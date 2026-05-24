target datalayout = "e-m:e-p:32:32-i8:8:32-i16:16:32-i64:64-n32"
target triple = "xtensa-unknown-unknown-unknown"

define void @selectiondag_combine_loop(i8 %a) {
entry:
  %cond = icmp eq i8 %a, 0
  %selected = select i1 %cond, i2 0, i2 -2
  %cmp = icmp eq i2 %selected, -1
  br i1 %cmp, label %done, label %done

done:
  ret void
}
