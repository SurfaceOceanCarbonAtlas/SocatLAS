#
# LAS configuration
#
my $PERLBIN = shift;
#
# Extra Perl goodies needed for this script.
#
use Cwd;              # getcwd()
use File::Basename;   # fileparse(), basename(), dirname()
use File::Copy;       # cp()
use File::Path;       # mkpath()

#
# Read previous configure results if they exist.
# 
my $configp = "config7.results";
if (-f $configp){
    do $configp;
}


print "\n\nConfiguring V8.x User Interface...\nIf you want to install the in-situ examples make sure you've loaded the sample data.\nSee the installation instructions at: http://ferret.pmel.noaa.gov/LAS/documentation/installer-documentation/installation/ for details.\n\n";
#
# Make sure Ferret environment variable has been set up
#   

my $ferrettype=$ENV{FERRETTYPE};

if ( $ferrettype eq "pyferret" ) {
    # Don't care if it fails, the default results will work...
    copy("JavaSource/resources/ferret/scripts/Py_LAS_results.jnl", "JavaSource/resources/ferret/scripts/LAS_results.jnl");
}

$LasConfig{ferrettype} = $ferrettype;

if (! $ENV{FER_DIR} ){
    print <<EOF; 
  Your FERRET environment has not been properly set up.
  (The environment variable FER_DIR is not defined)

  Have you executed "source your_system_path/ferret_paths" ?
  You need to do this before configuring LAS.
EOF
    exit 1;
}

# If pyferret, check for FER_DIR, PYTHONPATH and LD_LIBRARY_PATH
if ( $ferrettype eq "pyferret" ) {
    if (! $ENV{FER_DIR} ){
    print <<EOF; 
  Your PYFERRET environment has not been properly set up.
  (The environment variable FER_DIR is not defined)

  Have you executed "source your_system_path/pyferret_paths" ?
  You need to do this before configuring LAS.
EOF
    exit 1;
    }
    if (! $ENV{PYTHONPATH} ){
    print <<EOF; 
  Your PYFERRET environment has not been properly set up.
  (The environment variable PYTHONPATH is not defined
   and must be set to the local site modules to find pyferret)

  Have you executed "source your_system_path/pyferret_paths" ?
  You need to do this before configuring LAS.
EOF
    exit 1;
    }
    if (! $ENV{LD_LIBRARY_PATH} ){
    print <<EOF; 
  Your PYFERRET environment has not been properly set up.
  (The environment variable LD_LIBRARY_PATH is not defined
   and must be set to find the shared libraries for pyferret)

  Have you executed "source your_system_path/pyferret_paths" ?
  You need to do this before configuring LAS.
EOF
    exit 1;
    }
}
#
# Ferret environment variable names
#
my @EnvVars;
if ( $ferrettype eq "ferret" ) {
@EnvVars = qw(FER_DIR FER_DESCR FER_DATA FER_GRIDS FER_PALETTE
                 FER_GO FER_FONTS PLOTFONTS FER_EXTERNAL_FUNCTIONS DODS_CONF);
} else {
@EnvVars = qw(FER_DIR FER_DESCR FER_DATA FER_GRIDS FER_PALETTE
                 FER_GO FER_FONTS PLOTFONTS FER_EXTERNAL_FUNCTIONS DODS_CONF LD_LIBRARY_PATH PYTHONPATH);
}

#
# Check for appropriate Java virtual machine
#

my ($java, $autojava);
$autojava = $LasConfig{java};
if (! $autojava){
    $autojava = getExecutable('java');
}
while (! $java){
    print "Location of java executable: [$autojava] ";
    $java = <STDIN>;
    chomp($java);
    $java = $autojava if ! $java;
    if (! -x $java){
        print "$java is not an executable file\n";
        $java = undef;
    } else {
        print "Verifying Java version...\n";
        my $isJava = 0;
        open STATUS, "$java -version 2>&1|"
            or die "Can't run $java";
        my $line;
        while(<STATUS>){
            if (/ version /){
                $line = $_;
                last;
            }
        }
        close STATUS;
        if (defined $line){
            my @pieces = split(' ', $line);
            my $vstring = $pieces[$#pieces];
            $vstring =~ s/\"//g;
            my ($major,$minor) = split(/\./, $vstring);
            if ($major < 2 && $minor < 7){
                print "Java version is $vstring. Must have at least 1.7\n";
            } else {
                $isJava = 1;
            }
        }
        if (! $isJava){
            print "\n$java is not the Java program or not the right version\n\n";
            $java = undef;
        }
    }
}
$LasConfig{java} = $java;
print "You have a valid version of Java.\n\n";

#
# Search for Ferret, make sure it is correct version
#

if ( $ferrettype eq "ferret" ) {

$ENV{PATH} = $ENV{PATH} . ":/usr/local/ferret/bin/";
my ($ferret, $autoferret);
$autoferret = $LasConfig{ferret};
if (! $autoferret){
    $autoferret = getExecutable('ferret');
}
while (! $ferret){
    print "\nLocation of ferret executable: [$autoferret] ";
    $ferret = <STDIN>;
    chomp($ferret);
    $ferret = $autoferret if ! $ferret;
    if (! -x $ferret){
        print "$ferret is not an executable file\n";
        $ferret = undef;
    } else {
        print "Verifying Ferret version. This might take a few minutes...\n";
        my $isFerret = 0;
        my $testres = `echo exit | $ferret -nojnl`;
        my @lines = split /^/m, $testres;
        my $ferretVersion = "6.95";
        foreach my $line (@lines){
            my @words = split(/\s+/,$line);
            if ($words[1] =~ /Version|FERRET/){
                $words[2] =~ s/^v//;
                my $version = $words[2];
                if ($version < $ferretVersion){
                    print "\nYou need to upgrade Ferret.\n";
                    print "You need at least version $ferretVersion.\n\n";
                    exit 1;
                } else {
                    $isFerret = 1;
                }

            }
        }
        if (! $isFerret){
            print "\n$ferret is not the Ferret program\n\n";
            $ferret = undef;
        }
    }
}
print "\n\n";

$LasConfig{ferret} = $ferret;
my $ff = $LasConfig{ferret};
print "You have a valid version of Ferret at $ff\n\n";

} # end of if ferrettype eq ferret (with pyferret we found it in the pre-amble script).

my $autotds4 = $LasConfig{autotds4};
if (! $autotds4){
   $autotds4 = "yes";
}

while (! $tds4){
    print "Do you have a copy of TDS 4 installed?: [$autotds4] ";
    $tds4 = <STDIN>;
    chomp $tds4;
    $tds4 = $autotds4 if ! $tds4;
    if ($tds4 ne "yes" && $tds4 ne "no") {
        print "You must answer 'yes' or 'no'.\n";
        $tds4 = undef;
    }
}
if ( $tds4 eq "no" ) {
                    print "\nYou need to upgrade TDS.\n";
                    print "You need to be using TDS version 4.x.\n\n";
                    exit 1;
}

print "\n\n";

# Make a dummy properties file so the redirect filter can start
my $classesDir = "WebContent/WEB-INF/classes";
if ( ! -d $classesDir ) {
    mkdir $classesDir, 0755 or die "Can't create directory $classesDir: $!\n";
    print "Created a directory for the webapp classes and resources.\n\n";
}


#
# Get the path to access the LAS UI
#
$autopathname = $LasConfig{uipath};
$autopathname = "/las" if ! $autopathname;
print "\nYou must now specify the path name the Web client will use\n";
print "when accessing LAS. Unless you have more than one version of LAS\n";
print "installed, the default of $autopathname should be fine\n";

while (! $pathname){
    print "Enter path name for LAS: [$autopathname] ";
    $pathname = <STDIN>;
    chomp($pathname);
    $pathname = $autopathname if ! $pathname;
    if ($pathname !~ /^\//){
        print "Path name must begin with a '/'\n";
        undef $pathname;
    }
    $pathname =~ s/[\/]+$//g;
    my $count = split('\/', $pathname);
    if ($count > 2){
        print "Path name can only be one level deep (i.e. /las ok, /las/foo not)\n";
        undef $pathname;
    }
}
$LasConfig{uipath} = $pathname;
print "\n\n";
#
# Set up servlet in existing tomcat distribution:
#

$LasConfig{jakarta_home} = "/usr/local/tomcat" if !defined($LasConfig{jakarta_home});

my $jakarta_home = $LasConfig{jakarta_home};
my $different_Tomcat = $jakarta_home eq "las_servlet/jakarta" ? 1 : 0;

# NOTE:  There are no 'auto_' settings for the servlet ports
# NOTE:  'servlet_shutdown_port' and 'servlet_connector_port' don't seem to be used 
my ($servlet_port, $autoservlet_port);
my ($servlet_shutdown_port, $autoservlet_shutdown_port);
my ($servlet_connector_port, $autoservlet_connector_port);
$jakarta_home = getAnswer("Full path of Tomcat JAKARTA_HOME directory where you would like to deploy the servlet", $jakarta_home);
$LasConfig{jakarta_home} = $jakarta_home;
$LasConfig{webapps}="$jakarta_home/webapps";
my $jakarta_lib;
if ( -d "$jakarta_home/common/lib" ) {
   $jakarta_lib = "$jakarta_home/common/lib";
} else {
   $jakarta_lib = "$jakarta_home/lib";
}

my $appname = $LasConfig{uipath};
$appname =~ s/\///g;
$LasConfig{appname} = $appname;

print "\n\n";

$autoservlet_port = $LasConfig{servlet_port};
while (!$servlet_port){
    $servlet_port = getAnswer("Which HTTP port does the Tomcat server use",
                                       $autoservlet_port);
    $LasConfig{servlet_port} = $servlet_port;
}

print "\n\n";

my $hstn = `hostname`;
chomp $hstn;
my $tomcat_hostname;
my $autotomcathostname = $LasConfig{tomcat_hostname};
if (! $autotomcathostname){
    ($autotomcathostname) = gethostbyname $hstn;
    chomp $autotomcathostname;
}

while (! $tomcat_hostname){
    print "Enter the full domain name of the Tomcat Server (do not include the port number): [$autotomcathostname] ";
    $tomcat_hostname = <STDIN>;
    chomp $tomcat_hostname;
    $tomcat_hostname = $autotomcathostname if ! $tomcat_hostname;
    if ($tomcat_hostname !~ /\./){
        print "You must enter a full domain name\n";
        $tomcat_hostname = undef;
    }
}
$LasConfig{tomcat_hostname} = $tomcat_hostname;

print "\n\n";
#
# Get a title for the LAS
#
my $title;
my $autotitle = $LasConfig{title};
print "\nPlease provide a title for your LAS.\n";
print "This title will appear in the upper left hand corner of the LAS interface.\n";
while (! $title){
    print "Enter a title for the LAS server: [$autotitle] ";
    $title = <STDIN>;
    chomp($title);
    $title = $autotitle if ! $title;
}

$LasConfig{title} = $title;
print "\n\n";
#   
# Get an email address(es) for the LAS administrator(s)
#
my $email;
my $autoemail = $LasConfig{email};
print "\nProvide email address(es) for the administrator(s).\n";
    
    print "Enter a blank separated list email address(es): [$autoemail] ";
    $email = <STDIN>;
    chomp($email);
    $email = $autoemail if ! $email;

$LasConfig{email} = $email;
print "\n\n";

$LasConfig{proxy} = $proxy;

my $autoproxy = $LasConfig{proxy};
if (! $autoproxy){
   $autoproxy = "yes";
}

while (! $proxy){
    print "Do you plan to use a proxy pass or connector from the HTTP server to the tomcat server (recommended; instructions below): [$autoproxy] ";
    $proxy = <STDIN>;
    chomp $proxy;
    $proxy = $autoproxy if ! $proxy;
    if ($proxy ne "yes" && $proxy ne "no") {
        print "You must answer 'yes' or 'no'.\n";
        $proxy = undef;
    }
}
$LasConfig{proxy} = $proxy;

print "\n\n";

my $servlet_root_url="";
if ($LasConfig{proxy} eq "yes") {
    #
    # Get the hostname of the LAS server
    #
    my $hostname;
    my $hn = `hostname`;
    chomp $hn;
    my $autohostname = $LasConfig{hostname};
    if (! $autohostname){
        ($autohostname) = gethostbyname $hn;
        chomp $autohostname;
    }
    while (! $hostname){
        print "Enter the full domain name of the HTTP server that will be used as the proxy: [$autohostname] ";
        $hostname = <STDIN>;
        chomp $hostname;
        $hostname = $autohostname if ! $hostname;
        if ($hostname !~ /\./){
            print "You must enter a full domain name\n";
            $hostname = undef;
        }
    }
    $LasConfig{hostname} = $hostname;
    $servlet_root_url = $LasConfig{hostname};
} else {
    if ( $servlet_port != 80 ) {
        $servlet_root_url = $LasConfig{tomcat_hostname} . ":" . $servlet_port;
    } else {
        $servlet_root_url = $LasConfig{tomcat_hostname};
    }
}

# Make the log directory

my $logdir = $LasConfig{jakarta_home}."/content".$LasConfig{uipath}."/logs";
    if ( !(-d $logdir) ) {
       &File::Path::mkpath($logdir);
       print "Creating the $logdir directory.\n";
    }

# Get info about the TDS installation.

    my $serverConf = $LasConfig{jakarta_home}."/content".$LasConfig{uipath}."/conf/server";
    if ( !(-d $serverConf) ) {
       &File::Path::mkpath($serverConf);
       print "Creating the $serverConf directory.\n";
    }

#
# Get the temp dirs.
#
my $tds_temp = $serverConf."/temp";
if ( !(-d $tds_temp) ) {
   &File::Path::mkpath($tds_temp);
   print "Creating the $tds_temp directory.\n";
}
#
my $las_temp = $serverConf."/scripts/temp";
if ( !(-d $las_temp) ) {
   &File::Path::mkpath($las_temp);
   print "Creating the $las_temp directory.\n";
}

print "\n\n";

$LasConfig{tds_temp} = $tds_temp;
$LasConfig{las_temp} = $las_temp;

#
# Get the data dir.
#
my $tds_data = $serverConf."/data";
if ( !(-d $tds_data) ) {
   &File::Path::mkpath($tds_data);
   print "Creating the $tds_data directory.\n";
}
   $LasConfig{tds_data} = $tds_data;

# Make the dynamic data dir.
my $tds_dynadata = $tds_data."/dynamic";

if ( !(-d $tds_dynadata) ) {
   &File::Path::mkpath($tds_dynadata);
   print "Creating the $tds_dynadata directory for the dynamic data for user defined variables and comparison regridding.\n\n";
}
   $LasConfig{tds_dynadata} = $tds_dynadata;

# End of TDS info.


#
# Scripts to edit
#

my @Scripts = qw(build.xml
                 bin/initialize_check.sh
                 bin/addXML.sh
                 bin/addDiscrete.sh
                 bin/lasTest.sh
                 conf/example/sample_las.xml
                 conf/example/sample_ui.xml
                 conf/example/productserver.xml
                 JavaSource/resources/ferret/FerretBackendConfig.xml.base
                 JavaSource/resources/ferret/FerretBackendConfig.xml.pybase
                 JavaSource/resources/kml/KMLBackendConfig.xml
                 JavaSource/resources/database/DatabaseBackendConfig.xml
                 WebContent/WEB-INF/web.xml
                 JavaSource/log4j.xml
                 JavaSource/log4j2.xml
                 WebContent/TestLinks.html
                 );
my $mode = 0644;
my $xmode = 0755;
foreach my $script (@Scripts){
    my $template = "$script.in";
    open INSCRIPT, $template or die "Can't open template file $template";
    if (-f $script){
        if ( $script =~ "\.sh" ) {
           chmod $xmode, '$script';
        } else {
           chmod $mode, '$script';
        }
    }
    open OUTSCRIPT, ">$script" or die "Can't create output file $script";
    my $cust_name = $LasConfig{custom_name};
    my $cname;
    $cname = qq(src="$cust_name/custom.js") if $cust_name;
    my $cplinclude = "";
    $cplinclude = "$cust_name" if $cust_name;
    my $java_home = dirname(dirname($java));
    my $cdir = &Cwd::cwd();
    while (<INSCRIPT>){
        s/\@JAKARTA_HOME\@/$jakarta_home/g;
        s/\@JAKARTA_LIB\@/$jakarta_lib/g;
        s/\@JAVA_HOME\@/$java_home/g;
        s/\@FERRET\@/$LasConfig{ferret}/g;
        s/\@OUTPUT_ALIAS\@/$LasConfig{output_alias}/g;
        s/\@UIPATH\@/$LasConfig{uipath}/g;
        s/\@APPNAME\@/$LasConfig{appname}/g;
        s/\@SERVERHOST\@/$LasConfig{hostname}/g;
        s/\@TOMCATHOST\@/$LasConfig{tomcat_hostname}/g;
        s/\@PROXY\@/$LasConfig{proxy}/g;
        s/\@JSINCLUDE\@/$cname/g;
        s/\@CUSTOM_PERL_INCLUDE\@/$cplinclude/g;
        s/\@DB_HOST\@/$host/g;
        s/\@SERVLET_PORT\@/$servlet_port/g;
        s/\@SERVLET_SHUTDOWN_PORT\@/$servlet_shutdown_port/g;
        s/\@SERVLET_CONNECTOR_PORT\@/$servlet_connector_port/g;
        s/\@SERVLET_ROOT_URL\@/$servlet_root_url/g;
        s/\@MODULES_LIST\@/$modules_list/g;
        s/\@TITLE\@/$LasConfig{title}/g;
        s/\@ADMIN_EMAIL\@/$LasConfig{email}/g;
        s/\@LAS_TEMP\@/$LasConfig{las_temp}/g;
        s/\@WEBAPPS\@/$LasConfig{webapps}/g;
        s/\@TDS_DATA\@/$LasConfig{tds_data}/g;
        s/\@TDS_DYNADATA\@/$LasConfig{tds_dynadata}/g;
        s/\@TDS_TEMP\@/$LasConfig{tds_temp}/g;
        s/\@PWD\@/$cdir/g;
        s/\@PYEXE\@/$ENV{PYEXE}/g;
        print OUTSCRIPT $_;
    }
    close INSCRIPT;
    close OUTSCRIPT;
    if ( $script =~ "\.sh" ) {
       chmod $xmode, "$script";
    } else {
       chmod $mode, "$script";
    }
}



#
# Set up Ferret paths
#

$ferretConfig = "JavaSource/resources/ferret/FerretBackendConfig.xml";

print <<EOF;

Now setting up the Ferret environment variables for the server...
If you want to change them, edit 'JavaSource/resources/ferret/FerretBackendConfig.xml'


EOF

if (-f "JavaSource/resources/ferret/FerretBackendConfig.xml"){
    print "You already have a config file for your Ferret backend environment.\n";
    

    if ( getYesOrNo("Do you want to use this file") ) {
print <<EOF;
Using current file.
EOF
    } else {
print <<EOF;
The current file has been saved in: JavaSource/resources/ferret/FerretBackendConfig.xml.old
EOF
          system("mv $ferretConfig $ferretConfig.old");
          if ( $ferrettype eq "ferret" ) {
            copy ("$ferretConfig.base","$ferretConfig") or
          die "Could not get FerretBackendConfig.xml initialization file";
          } else {
            copy ("$ferretConfig.pybase","$ferretConfig") or
          die "Could not get FerretBackendConfig.xml initialization file";
          }
          printENV($ferretConfig, @EnvVars);
   }
} else {
print <<EOF;

Creating a  new 'JavaSource/resources/ferret/FerretBackendConfig.xml'
based on your current environment variable settings.  

The current file has been saved in: JavaSource/resources/ferret/FerretBackendConfig.xml.old

EOF
       if ( $ferrettype eq "ferret" ) {
         copy("$ferretConfig.base","$ferretConfig") or
       die "Could not get FerretBackendConfig.xml initialization file";
       } else {
         copy("$ferretConfig.pybase","$ferretConfig") or
       die "Could not get FerretBackendConfig.xml initialization file";
       }
       printENV($ferretConfig, @EnvVars);
}


# Set up DODS Configuration and Cache stuff
#

my $dodsConfDir = $serverConf."/dods";
if (! -d $dodsConfDir){
   mkdir $dodsConfDir, 0775 or die "Can't create directory $dodsConfDir: $!\n";
}
my $dodsCacheDir = "$dodsConfDir/.dods_cache";
if (! -d $dodsCacheDir){
   mkdir $dodsCacheDir, 0775 or die "Can't create directory $dodsCacheDir: $!\n";
}

my $dodsConf = "$dodsConfDir/.dodsrc";
if (! -f $dodsConf){
   open DOUT, ">$dodsConf" or die "Can't open $dodsConf for writing";
   print DOUT "\# DODS client configuration file. See the DODS\n";
   print DOUT "\# users guide for information.\n";
   print DOUT "USE_CACHE=1\n";
   print DOUT "MAX_CACHE_SIZE=100\n";
   print DOUT "MAX_CACHED_OBJ=5\n";
   print DOUT "IGNORE_EXPIRES=0\n";
   print DOUT "CACHE_ROOT=$dodsCacheDir\n";
   print DOUT "DEFAULT_EXPIRES=86400\n";
   print DOUT "ALWAYS_VALIDATE=0\n";
   close DOUT;
}

my $dodsConf_no_cache = "$dodsConfDir/.dodsrc_no_cache";
if (! -f $dodsConf_no_cache){
   open DOUT, ">$dodsConf_no_cache" or die "Can't open $dodsConf_no_cache for writing";
   print DOUT "\# DODS client configuration file. See the DODS\n";
   print DOUT "\# users guide for information.  This version of the\n";
   print DOUT "\# file has caching turned off.\n";
   print DOUT "USE_CACHE=0\n";
   print DOUT "MAX_CACHE_SIZE=100\n";
   print DOUT "MAX_CACHED_OBJ=5\n";
   print DOUT "IGNORE_EXPIRES=0\n";
   print DOUT "CACHE_ROOT=$dodsCacheDir\n";
   print DOUT "DEFAULT_EXPIRES=86400\n";
   print DOUT "ALWAYS_VALIDATE=0\n";
   close DOUT;
}

# Regardless of whether the examples are to be installed, get the latest operations file.


    my $ops_in = "conf/example/operationsV7.xml";
    my $ops_out = $serverConf."/operationsV7.xml";

    if ( -f $ops_out ) { 
         print "You already have an operationsV7.xml file for your\n";
         print "product server in $ops_out.\n";
         my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
         $year += 1900;
         my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
         my $m = $mday;
         if ( $mday < 10 ) {
              $m = "0".$mday;
         }
         my $ops_date = $year."-".$abbr[$mon]."-".$m;
         my $ops_bak = $ops_out."-".$ops_date.".bak";
         print "Creating an back up in $ops_bak.\n";
         if (!copy($ops_out, $ops_bak)){
             print "Couldn't copy $ops_out to $ops_bak\n";
             exit 1;
         }
     }
     if (!copy($ops_in, $ops_out)){
         print "Couldn't copy $ops_in to $ops_out\n";
     }

if ( getYesOrNo("Do you want to install the example data set configuration") ) {

    my @sample_in = ();
    my @sample_out = ();

    $sample_in[0] = "conf/example/sample_las.xml";
    $sample_out[0] = $serverConf."/las.xml";
    $sample_in[1] = "conf/example/productserver.xml";
    $sample_out[1] = $serverConf."/productserver.xml";
    $sample_in[2] = "conf/example/sample_ui.xml";
    $sample_out[2]= $serverConf."/ui.xml";
    $sample_in[3] = "conf/example/coads.xml";
    $sample_out[3] = $serverConf."/coads.xml";
    $sample_in[4] = "conf/example/DODS_IRI_NOAA_NCEP_EMC_CMB_Pac_ocean.xml";
    $sample_out[4] = $serverConf."/DODS_IRI_NOAA_NCEP_EMC_CMB_Pac_ocean.xml";
    $sample_in[5] = "conf/example/levitus.xml";
    $sample_out[5] = $serverConf."/levitus.xml";
    $sample_in[6] = "conf/example/ocean_atlas_subset.xml";
    $sample_out[6] = $serverConf."/ocean_atlas_subset.xml";
    $sample_in[7] = "conf/example/options.xml";
    $sample_out[7] = $serverConf."/options.xml";
    $sample_in[8] = "conf/example/trajectory_ui.xml";
    $sample_out[8] = $serverConf."/trajectory_ui.xml";
    $sample_in[9] = "conf/example/profile_ui.xml";
    $sample_out[9] = $serverConf."/profile_ui.xml";
    $sample_in[10] = "conf/example/timeseries_ui.xml";
    $sample_out[10] = $serverConf."/timeseries_ui.xml";
    $sample_in[11] = "conf/example/timeseries_only_ui.xml";
    $sample_out[11] = $serverConf."/timeseries_only_ui.xml";
    $sample_in[12] = "conf/example/point_ui.xml";
    $sample_out[12] = $serverConf."/point_ui.xml";

    for ( my $i = 0; $i <= $#sample_in; $i++ ) {
       if ( -f $sample_out[$i] ) {
           print "You already have this XML configuration file for your\n";
           print "product server in $sample_out[$i].\n";
           if (! getYesOrNo("Overwrite this file", 1)){
              print "I will not change this configuration\n";
           } else {
              if (!copy($sample_in[$i], $sample_out[$i])){
                  print "Couldn't copy $sample_in[$i] to $sample_out[$i]\n";
              }
           }
       } else {
           if (!copy($sample_in[$i], $sample_out[$i])){
               print "Couldn't copy $sample_in[$i] to $sample_out[$i]\n";
           }
       }
    }
 
    mkdir "WebContent/docs";
   
    if (!copy("conf/example/levitus_monthly.html","WebContent/docs/levitus_monthly.html")){
       print "Couldn't copy levitus_monthly.html.\n";
    }
 }

    print "Building addXML and the servlet war file.\n";
    system("ant addxml-build; ant deploy");
    if ($? != 0) {
        print "Build failed!\n";
        exit 1;
    }
    print "\n\n";

    createScripts();

    print "You can test your F-TDS setup by running the LASTest suite.\n";
    print "To run the tests run these commands.\n";
    print "cd test/LASTest\n";
    print "ant lastest -Df=1\n";

    print "\n\n";

    print "You must restart your Tomcat server.\n";
    print "We've created some scripts to help you do that.  See: stopserver.sh, startserver.sh and rebootserver.sh\n";

    print "\n\n";
    my $app = $LasConfig{appname};
    print "Your user interface to LAS is at: http://$servlet_root_url/$app/\n";


#
# Save configuration
#

if (!&saveConfig){
    print <<EOF;

Couldn't save configuration results. The next time you run the
configuration script, you will have to reenter all of the
configuration data.

EOF
}




sub saveConfig {
    my $status = open CONFIG, ">$configp";
    if (! $status){
        print "\nCan't write $configp file\nIf you rerun the configuration, you will have to reenter all of the configuration parameters.\n";
        return 0;
    }
    foreach my $key (keys %LasConfig){
        print CONFIG '$LasConfig{',$key,'} = \'',$LasConfig{$key},"';\n";
    }
    print CONFIG "1;\n";
    close CONFIG;
}

sub createScripts {

my $jakarta_home = $LasConfig{jakarta_home};
my $java_home = dirname(dirname($java));
my $workdir = $LasConfig{uipath};
my $removeWork = $jakarta_home."/work/Catalina/localhost".$workdir;

open SCRIPT_OUT, ">startserver.sh" or die "Can't open startserver.sh";
print SCRIPT_OUT <<EOL;
#!/bin/sh
JAVA_HOME="$java_home"
JAVA_OPTS="-Djava.awt.headless=true -Xmx2048M -Xms2048M"
CATALINA_PID="$LasConfig{webapps}/UI_PID"
CATALINA_HOME="$LasConfig{jakarta_home}"
export JAVA_HOME JAVA_OPTS CLASSPATH CATALINA_PID CATALINA_HOME
rm -rf $removeWork
exec $jakarta_home/bin/catalina.sh start
EOL
my $mode = 0755;
close SCRIPT_OUT;
chmod $mode,"startserver.sh";

open SCRIPT_OUT, ">stopserver.sh" or die "Can't open stopserver.sh";
print SCRIPT_OUT <<EOL2;
#!/bin/sh
JAVA_HOME="$java_home"
JAVA_OPTS="-Djava.awt.headless=true -Xmx256M -Xms256M"
CATALINA_PID="$LasConfig{webapps}/UI_PID"
CATALINA_HOME="$LasConfig{jakarta_home}"
export JAVA_HOME JAVA_OPTS CLASSPATH CATALINA_PID CATALINA_HOME
exec $jakarta_home/bin/catalina.sh stop
EOL2

close SCRIPT_OUT;
chmod $mode,"stopserver.sh";

my $stopsrv = &Cwd::cwd()."/stopserver.sh";
my $startsrv = &Cwd::cwd()."/startserver.sh";
open SCRIPT_OUT, ">rebootserver.sh" or die "Can't open rebootserver.sh";
print SCRIPT_OUT <<EOL3;
#! /bin/sh
#

# Attempt to shutdown the server gracefully.
$stopsrv

# Wait to let things shutdown.
sleep 5

# Check to see if it is still running.
ps `cat $LasConfig{webapps}/UI_PID`
STATUS=$?
 if [ \$STATUS -eq 0 ] ; then
     # LAS UI did not shutdown ok.  Kill it.
     kill -9 `cat $LasConfig{webapps}/UI_PID`
 else
     # LAS UI shutdown ok.
     continue
 fi

# Start the server again.  Answer the question 'yes' if necessary.
$startsrv
EOL3

close SCRIPT_OUT;
chmod $mode,"rebootserver.sh";
}

sub getExecutable {
    my ($file) = @_;
    foreach my $path (split ':',$ENV{PATH}){
        my $checkfile = "$path/$file";
        if (-x "$checkfile"){
            return $checkfile;
        }
    }
    "";
}
sub getAnswer($$) {
    my ($mess, $default) = @_;
    print "$mess: [$default] ";
    my $answer = <STDIN>;
    chomp($answer);
    $answer = $default if ! $answer;
    return $answer;
}
    sub getYesOrNo {
        my $prompt = shift;
        my $useNo = shift;
        my $default = $useNo ? "no" : "yes";
        print "$prompt? [$default] ";
        my $ans = <STDIN>; 
        chomp($ans);
        $ans = $default if ! $ans;
        if ($ans !~ /^[yY]/){
            return 0;
        }
        return 1; 
    }    

sub trim($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

sub printENV($ferretConfig, @EnvVars) {
       open CONFIGFILE, ">>$ferretConfig"
           or die "Couldn't open config file $ferretConfig";

        print CONFIGFILE '    <environment>',"\n";
        foreach my $var (@EnvVars){
            $ENV{$var} = ". " . $ENV{$var} if ($var !~ /FER_FONTS/ && $var !~ /PLOTFONTS/ && $var !~ /PYTHONPATH/ && $var !~ /LD_LIBRARY_PATH/);
            if ($var =~ /FER_GO|FER_PALETTE/){
                $ENV{$var} = "scripts jnls jnls/insitu jnls/section " . $ENV{$var};
                $ENV{$var} = $LasConfig{custom_name} . " " . $ENV{$var}
                    if $LasConfig{custom_name};
            } elsif ($var =~ /FER_DATA/){
                $ENV{$var} = "./data " . $ENV{$var};
            } elsif ($var =~ /FER_DESCR/){
                $ENV{$var} = "des " . $ENV{$var};
            } elsif ($var =~ /DODS_CONF/){
                $ENV{$var} = $serverConf."/dods/.dodsrc";
            }

            my @values = split(' ',$ENV{$var});

            # Trim so ". " and "." match
            foreach my $value (@values) {
               $value = trim($value);
            }

            #Extract unique entries, see perl FAQ
            undef %saw;
            @saw{@values} = ();
            @out = sort keys %saw;  # remove sort if undesired
    
            print CONFIGFILE '        <variable>',"\n";
            print CONFIGFILE '            <name>',$var,'</name>',"\n";
            foreach my $value (@out) {
               $value = trim($value);
               print CONFIGFILE '             <value>',$value,'</value>',"\n";
            }
            print CONFIGFILE '        </variable>',"\n";
        }
        print CONFIGFILE '    </environment>',"\n";
        print CONFIGFILE '</application>',"\n";
        close CONFIGFILE;
     }
