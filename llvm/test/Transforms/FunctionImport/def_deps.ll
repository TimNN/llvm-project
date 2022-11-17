; Test to ensure that if a definition is imported, already-present declarations
; are updated as necessary: Definitions from the same module may be optimized
; together. Thus care must be taken when importing only a subset of the
; definitions from a module (because other referenced definitions from that
; module may have been changed by the optimizer and may no longer match
; declarations already present in the module being imported into).

; Generate bitcode for the definitions, and run Dead Argument Elimination on
; them. This makes `@outer` call `@inner` with `poison` as the argument, while
; also removing `noundef` from `@inner`.
; RUN: opt -module-summary -passes=deadargelim %p/Inputs/def_deps.ll -o %t.inputs.def_deps.bc

; Now generate the remaining bitcode and index, and run the function import.
; RUN: opt -module-summary %s -o %t.main.bc
; RUN: llvm-lto -thinlto -o %t.summary %t.main.bc %t.inputs.def_deps.bc
; RUN: opt -passes=function-import -summary-file %t.summary.thinlto.bc %t.main.bc -S 2>&1 \
; RUN:   | FileCheck %s

define void @main()  {
  call void @outer(i32 noundef 1)
  call void @inner(i32 noundef 1)
  ret void
}

; Because `@inner` is `noinline`, it should not get imported. However, the
; `noundef` should be removed.
; CHECK: declare void @inner(i32)
declare void @inner(i32 noundef)

; `@outer` should get imported.
; CHECK: define available_externally void @outer(i32 noundef %0)
; CHECK-NEXT: call void @inner(i32 poison)
declare void @outer(i32 noundef)
