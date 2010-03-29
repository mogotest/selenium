# 1.x release stuff
version = "1.0.3"

java_jar(:name => "old_selenium-server-coreless",
    :srcs  => [ "remote/server/src/java/**/*.java", "remote/common/src/java/**/*.java" ],
    :resources => [
      {
        "remote/server/src/java/org/openqa/jetty/http/mime.properties" => "org/openqa/jetty/http/mime.properties",
        "remote/server/src/java/org/openqa/jetty/http/encoding.properties" => "org/openqa/jetty/http/encoding.properties",
      },
      "remote/server/src/java/customProfileDir*",
      "remote/server/src/java/cybervillains",
      "remote/server/src/java/hudsuckr",
      "remote/server/src/java/killableprocess",
      "remote/server/src/java/konqueror",
      "remote/server/src/java/opera",
      "remote/server/src/java/sslSupport",
      "remote/server/src/java/VERSION.txt"
    ],
    :deps => [
               :chrome,
               :htmlunit,
               :ie,
               :firefox,
               :remote_common,
               :selenium,
               :support,
               "remote/server/lib/runtime/*.jar"
             ])
             
           
java_jar(:name => "old_selenium-server-sources", :resources => ["remote/server/src/java/org", "remote/common/src/java/org"])
           
task :old_javadocs => [:common, :firefox, :htmlunit, :jobbie, :remote, :support, :chrome, :selenium] do
 mkdir_p "build/old_javadocs", :verbose => false
  sourcepath = ""
  classpath = "support/lib/runtime/hamcrest-all-1.1.jar"
  %w(common firefox jobbie htmlunit support remote/common remote/client chrome selenium).each do |m|
    sourcepath += ":#{m}/src/java"
  end
  cmd = "javadoc -windowtitle 'Selenium Remote Control #{version}' -d build/old_javadocs -sourcepath #{sourcepath} -classpath #{classpath} -subpackages org.openqa.selenium -subpackages com.thoughtworks"
  if (windows?) 
    cmd = cmd.gsub(/\//, "\\").gsub(/:/, ";") 
  end
  sh cmd
end

task :old_release => [:'old_selenium-server-coreless', :'old_selenium-server-sources', :old_javadocs, :'selenium-server-standalone'] do
  base = "build/old_release/selenium-remote-control-#{version}"
  
  # drop in overlay
  mkdir_p base, :verbose => false
  cp_r Dir.glob("1.x_overlay/*"), base
  
  # javadocs
  ss_dir = "#{base}/selenium-server-#{version}"
  mkdir_p ss_dir
  javadocs_dir = "#{ss_dir}/javadocs/"
  mkdir_p javadocs_dir
  cp_r Dir.glob("build/old_javadocs/*"), javadocs_dir
  
  # server-coreless
  cp "build/old_selenium-server-coreless.jar", "#{ss_dir}/selenium-server-coreless.jar"
  
  # standalone version
  cp "build/selenium-server-standalone.jar", "#{ss_dir}/selenium-server.jar"
  
  # cyber villians cert
  mkdir_p "#{ss_dir}/sslSupport"
  cp "remote/server/src/java/sslSupport/cybervillainsCA.cer", "#{ss_dir}/sslSupport"
  
  # sources jar
  cp "build/old_selenium-server-sources.jar", "#{ss_dir}/selenium-server-sources.jar"
  
  # zip it all up
  sh "cd #{base} && jar cMf ../selenium-remote-control-#{version}.zip *", :verbose => false
end

# End 1.x release stuff
