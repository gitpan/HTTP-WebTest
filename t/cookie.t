print "1..1\n";
if (system("export WEBTEST_LIB=blib/lib; ./wt t/cookie.wt")) {
   print "not ok 1\n";
} else {
   print "ok 1\n";
}
