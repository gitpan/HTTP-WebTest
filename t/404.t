print "1..1\n";
if (system("export WEBTEST_LIB=blib/lib; ./wt t/404.wt")) {
   print "ok 1\n";
} else {
   print "not ok 1\n";
}
