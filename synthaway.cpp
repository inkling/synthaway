//
// synthaway.cpp
// synthaway
//
// Copyright (c) 2012 Inkling Systems, Inc.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//    http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include <clang/AST/ASTConsumer.h>
#include <clang/AST/ASTContext.h>
#include <clang/AST/ASTContext.h>
#include <clang/AST/Attr.h>
#include <clang/AST/DeclObjc.h>
#include <clang/AST/ExprObjc.h>
#include <clang/AST/Stmt.h>
#include <clang/Frontend/CompilerInstance.h>
#include <clang/Frontend/FrontendActions.h>
#include <clang/Lex/Lexer.h>
#include <clang/Lex/Preprocessor.h>
#include <clang/Rewrite/Core/Rewriter.h>
#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <llvm/Support/CommandLine.h>
#include <set>

#pragma clang diagnostic ignored "-Wc++11-extensions"

using namespace clang;
using namespace clang::tooling;

static const char *kMoreHelpText = 
  "\tSee README.markdown for details.\n"
  "\n";


class SynthesizeRemovalConsumer : public ASTConsumer {
public:
  SynthesizeRemovalConsumer(CompilerInstance &CI);
  virtual void HandleTranslationUnit(ASTContext &) override;
  
protected:
  void removeSynthesizeDirectives(DeclContext *DC);
  void processDeclContext(DeclContext *DC);  
  void processStmt(Stmt *S, DeclContext *DC);

  CompilerInstance *compilerInstance;
  Preprocessor *preprocessor;
  Rewriter rewriter;
  ASTContext *astContext;
  
  std::set<ObjCPropertyImplDecl *> removeSet;
  std::set<Expr *> renameSet;
  
protected:
  // utility methods
  std::string loc(SourceLocation L);
  std::string range(SourceRange R);
  bool shouldIgnore(SourceLocation L);
  void renameLocation(SourceLocation L, std::string& N);
};


SynthesizeRemovalConsumer::SynthesizeRemovalConsumer(CompilerInstance &CI)
  : compilerInstance(&CI)
  , preprocessor(&CI.getPreprocessor()) {
  rewriter.setSourceMgr(CI.getSourceManager(), CI.getLangOpts());
}

void SynthesizeRemovalConsumer::HandleTranslationUnit(ASTContext &C)
{
  if (compilerInstance->getDiagnostics().hasErrorOccurred()) {
    return;
  }
  
  astContext = &C;
  auto TUD = C.getTranslationUnitDecl();  
  removeSynthesizeDirectives(TUD);
  processDeclContext(TUD);

  if (removeSet.empty()) {
    // nothing is removed
    llvm::errs() << "nothing to remove.\n";
    return;
  }

  SourceManager &SM = rewriter.getSourceMgr();
  FileID FID = SM.getMainFileID();
  const FileEntry* F = SM.getFileEntryForID(FID);
  
  // backup the source
  std::string backupFilename = std::string(F->getName()) + ".bak";
  std::string errInfo;
  llvm::raw_fd_ostream backupStream(backupFilename.c_str(), errInfo,
    llvm::raw_fd_ostream::F_Binary);
  if (!errInfo.empty()) {
    llvm::errs() << "Cannot write backup file: " << backupFilename <<
      ", error info: " << errInfo << "\n";
    return;
  }
  backupStream << SM.getBufferData(FID);
  backupStream.flush();

  // write the output
  llvm::raw_fd_ostream outStream(F->getName(), errInfo,
    llvm::raw_fd_ostream::F_Binary);
  if (!errInfo.empty()) {
    llvm::errs() << "Cannot write output file: " << F->getName() <<
      ", error info: " << errInfo << "\n";
    return;
  }
    
  const RewriteBuffer *RB = rewriter.getRewriteBufferFor(FID);
  RB->write(outStream);
  outStream.flush();
}

void SynthesizeRemovalConsumer::removeSynthesizeDirectives(DeclContext *DC)
{
  for(auto I = DC->decls_begin(), E = DC->decls_end(); I != E; ++I) {

    // encounters @implementatian
    if (auto D = dyn_cast<ObjCImplDecl>(*I)) {
      
      // iterate through all the @synthesize / @dynamic directives
      for (auto PI = D->propimpl_begin(), PE = D->propimpl_end(); PI != PE;
        ++PI) {
        auto P = *PI;
        
        auto SR = P->getSourceRange();
        
        // ignore if it's already an automatic @synthesize
        if (SR.getBegin().isInvalid()) {
          continue;
        }
        
        // ignore @dynamic
        if (P->getPropertyImplementation() == ObjCPropertyImplDecl::Dynamic) {
          continue;
        }
        
        // if the ivar is not declared in the place where @synthesize is
        // (i.e. it is backed by some real ivar declared in @interface),
        // don't remove it
        auto PID = P->getPropertyIvarDecl();
        if (P->getPropertyIvarDeclLoc() != PID->getLocation()) {
          continue;
        }
        
        // get the context in which the @property resides
        auto PD = P->getPropertyDecl();
        auto PDC = PD->getDeclContext();
        auto ID = dyn_cast<ObjCInterfaceDecl>(PDC);

        if (!ID) {
          continue;
        }

        // see if it's an @interface definition; this is false for @protocol
        // and we can only remove the synthesize decl for properties
        // declared within an @interface and not in @protocol
        if (!ID->isThisDeclarationADefinition()) {
          continue;
        }

        // check if the interface has the attribute
        // __attribute__((objc_requires_property_definitions)); if yes, the
        // directive cannot be removed
        bool attrObjCRequiresPropertyDefs = false;
        for (auto AI = ID->attr_begin(), AE = ID->attr_end();
          AI != AE; ++AI) {
          if ((*AI)->getKind() == attr::ObjCRequiresPropertyDefs) {
            attrObjCRequiresPropertyDefs = true;
            break;
          }
        }

        if (attrObjCRequiresPropertyDefs) {
          continue;
        }

        // if there is both a manual getter *and* setter, it's equivalent to
        // a @dynamic, so we have to skip it        
        auto GD = D->getInstanceMethod(PD->getGetterName());
        auto SD = D->getInstanceMethod(PD->getSetterName());
        if (GD && SD) {
          continue;
        }

        // another case for read-only properties
        if (GD && PD->isReadOnly()) {
          continue;
        }
            
        // scan past the ; token, get the end location
        SourceLocation EL = Lexer::findLocationAfterToken(SR.getEnd(),
          tok::semi, astContext->getSourceManager(),
          astContext->getLangOpts(), false);

        // probably run into a comma (compound directive)
        if (EL.isInvalid()) {
          continue;
        }
        
        // if it's a sub-directive after the comma, scan from the
        // beginning of the @synthesize token
        bool isCompoundDirective = false;
        const char *BCD = astContext->getSourceManager()
          .getCharacterData(SR.getBegin());
        const char *ECD = astContext->getSourceManager()
          .getCharacterData(EL);
          
        while (BCD != ECD) {
          if (*BCD == ',') {
            isCompoundDirective = true;
            break;
          }
          ++BCD;
        }
        
        if (isCompoundDirective) {
          continue;
        }
            
        // check if the synthesized ivar name is not the same
        // as the property's name plus underscore              
        std::string PIDN = PID->getNameAsString();
        std::string PDN = PD->getNameAsString();
              
        // handle the case where it's not @synthesize x = _x;
        std::string underscored = std::string("_") + PDN;
        if (PIDN != PDN) {
          if (PIDN != underscored) {
            continue;
          }
        }

        // see if the property is actually an ivar name of 
        // some parent class!
        auto IF = preprocessor->getIdentifierInfo(underscored);
        if (IF) {                    
          auto IVDL = ID->lookupInstanceVariable(IF);
          if (IVDL && IVDL->getContainingInterface() != ID) {
            continue;
          }                    
        }
        
        // if parent class also have a property of the same name,
        // but of a different type, we can't remove it
        bool isOverridingProperty = false;
        auto S = ID->getSuperClass();                  
        while (S) {
          auto SP = S->FindPropertyVisibleInPrimaryClass(
            PD->getIdentifier());
          
          if (SP && (SP != PD)) {
            isOverridingProperty = true;
            break;
          }
          
          S = S->getSuperClass();
        }
        
        if (isOverridingProperty) {
          continue;
        }

        // do the removal: record the removed directive
        removeSet.insert(P);
      
        // we want to remove the entire line if it becomes empty
        Rewriter::RewriteOptions RO;
        RO.RemoveLineIfEmpty = true;

        // and remove the @synthesize
        SourceRange RSR(SR.getBegin(), EL);
        rewriter.RemoveText(RSR, RO);
      } // PI
    } // D
    
    // descend into the next level (namespace, etc.)    
    if (auto innerDC = dyn_cast<DeclContext>(*I)) {
      removeSynthesizeDirectives(innerDC);
    }
  } // DC
}

void SynthesizeRemovalConsumer::processDeclContext(DeclContext *DC)
{  
  for(auto I = DC->decls_begin(), E = DC->decls_end(); I != E; ++I) {
    if (auto D = dyn_cast<ObjCMethodDecl>(*I)) {
      // handle methods
      if (auto B = D->getBody()) {
        processStmt(B, D);
      }
    }
    else if (auto D = dyn_cast<BlockDecl>(*I)) {
      // handle blocks in a method; find the parent context first
      DeclContext *P = D->getParent();
      while (P) {
        if (dyn_cast<ObjCMethodDecl>(P)) {
          break;
        }
        P = P->getParent();
      }
      
      // only when P is a ObjCMethodDecl can me proceed
      if (P) {
        if (auto B = D->getBody()) {
          processStmt(B, P);
        }      
      }
    }

    // descend into the next level (for namespace, blocks, etc.)    
    if (auto innerDC = dyn_cast<DeclContext>(*I)) {
      processDeclContext(innerDC);
    }
  }
}

void SynthesizeRemovalConsumer::processStmt(Stmt *S, DeclContext *DC)
{
  if (!S) {
    return;
  }

  if (auto OPE = dyn_cast<OpaqueValueExpr>(S)) {
    // descend into an opaque expr's source exrp
    if (auto E = OPE->getSourceExpr()) {
      processStmt(E, DC);
    }
  }
  else if (auto E = dyn_cast<ObjCIvarRefExpr>(S)) {
    // handle ivar ref expressions: see if we have renamed this before
    if (renameSet.find(E) == renameSet.end()) {
      // the statement is in the method context
      auto M = dyn_cast<ObjCMethodDecl>(DC);
      
      // get the ivar decl of the ref expr
      auto IVD = E->getDecl(); 
      
      // get the @implementatian
      auto IMPL = dyn_cast<ObjCImplDecl>(M->getParent());
      
      if (M && IVD && IMPL) {
        auto PD = IMPL->FindPropertyImplIvarDecl(IVD->getIdentifier());
        bool inRemoveSet = removeSet.find(PD) != removeSet.end();
        if (PD && inRemoveSet) {
          std::string name = IVD->getNameAsString();
          
          // if it dosen't have the '_' prefix, rename it
          if (name.length() > 0 && name[0] != '_') {
            std::string replName = std::string("_") + name;
            renameLocation(E->getLocation(), replName);

            // and add to the rename set
            renameSet.insert(E);
          }
        }
      }
    }
  }

  for (auto I = S->child_begin(), E = S->child_end(); I != E; ++I) {
    processStmt(*I, DC);
  }
}

std::string SynthesizeRemovalConsumer::loc(SourceLocation L) {
  std::string src;
  llvm::raw_string_ostream sst(src);
  L.print(sst, astContext->getSourceManager());
  return sst.str();
}

std::string SynthesizeRemovalConsumer::range(SourceRange R) {
  std::string src;
  llvm::raw_string_ostream sst(src);
  sst << "(";
  R.getBegin().print(sst, astContext->getSourceManager());
  sst << ", ";
  R.getEnd().print(sst, astContext->getSourceManager());
  sst << ")";
  return sst.str();
}

bool SynthesizeRemovalConsumer::shouldIgnore(SourceLocation L) {
  if (!L.isValid()) {
    return true;
  }

  SourceManager &SM = astContext->getSourceManager();
  FullSourceLoc FSL(L, SM);
  const FileEntry *FE = SM.getFileEntryForID(FSL.getFileID());
  if (!FE) {
    // attempt to get the spelling location
    auto SL = SM.getSpellingLoc(L);
    if (!SL.isValid()) {
      return true;
    }
    
    FullSourceLoc FSL2(SL, SM);
    FE = SM.getFileEntryForID(FSL2.getFileID());
    if (!FE) {
      return true;
    }
  }

  return false;
}

void SynthesizeRemovalConsumer::renameLocation(SourceLocation L,
  std::string& N) {
  if (L.isMacroID()) {        
    // TODO: emit error using diagnostics
    SourceManager &SM = astContext->getSourceManager();
    if (SM.isMacroArgExpansion(L) || SM.isInSystemMacro(L)) {
      // see if it's the macro expansion we can handle
      // e.g.
      //   #define call(x) x
      //   call(y());   // if we want to rename y()
      L = SM.getSpellingLoc(L);
      
      // this falls through to the rename routine below
    }
    else {
      // if the spelling location is from an actual file that we can
      // touch, then do the replacement, but show a warning          
      SourceManager &SM = astContext->getSourceManager();
      auto SL = SM.getSpellingLoc(L);
      FullSourceLoc FSL(SL, SM);
      const FileEntry *FE = SM.getFileEntryForID(FSL.getFileID());
      if (FE) {
        llvm::errs() << "Warning: Rename attempted as a result of macro "
                     << "expansion may break things, at: " << loc(L) << "\n";            
        L = SL;
        // this falls through to the rename routine below
      }
      else {
        // cannot handle this case
        llvm::errs() << "Error: Token is resulted from macro expansion"
          " and is therefore not renamed, at: " << loc(L) << "\n";
        return;
      }
    }
  }
    
  if (shouldIgnore(L)) {
    return;
  }
    
  auto LE = preprocessor->getLocForEndOfToken(L);
  if (LE.isValid()) {        
    // getLocWithOffset returns the location *past* the token, hence -1
    auto E = LE.getLocWithOffset(-1);
    rewriter.ReplaceText(SourceRange(L, E), N);
  }
}  


class SynthesizeRemovalAction : public ASTFrontendAction {
public:
    virtual ASTConsumer *CreateASTConsumer(CompilerInstance &CI,
      llvm::StringRef filename) {
      return new SynthesizeRemovalConsumer(CI);
    }
};


int main(int argc, const char **argv) {
  tooling::CommonOptionsParser parser(argc, argv);
  tooling::ClangTool Tool(parser.getCompilations(),
      parser.getSourcePathList());
  llvm::cl::extrahelp H(kMoreHelpText);
  return Tool.run(newFrontendActionFactory<SynthesizeRemovalAction>());
}
