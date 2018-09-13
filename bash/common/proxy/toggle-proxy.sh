#!/bin/sh

#This script toggles all the proxy settings in a MAC environment
#The proxy value may be passed in from the command line while execting the scripts
#If no proxy value is passed in then the script guesses a proxy value
#If the user wants to enable to proxies then the script sets the proxies
#for env vars (bash_profile) and MAVEN_SETTINGS_FILE
#If the user wants to disable proxies then the script disables all the proxies

#This is the list of files updated:
# ~/.bash_profile
# ~/.m2/settings.xml

ScriptDir="$( pwd )"

usage() {
  echo
  echo Usage:
  echo $0 [--help] [--enable] [--disable] [--clean]
  echo
  echo "Where : <host> is the hostname of your proxy"
  echo "        <port:8080> is the port on the proxy server, defaults to 8080"
  echo
  echo "When Enabling proxies, Please select and enter the proxy server name - HOST:PORT"
  echo "example - PITC-Zscaler-US-SanRamon.proxy.corporate.ge.com:8080"
  echo
  echo "Options:"
  echo "    --help      Display this help message"
  echo "    --enable    Set proxy settings"
  echo "    --disable   Unset proxy settings"
  echo "    --clean     Delete proxy settings"
  echo
}

guessProxy() {
  export GUESSED_PROXY_HOST=`wget -O - http://corp.setpac.ge.com/pac.pac --no-proxy 2>/dev/null | grep -i "^var\w* main_proxy" | sed "s/.*\"PROXY\s* \([^\";]*\)\"*;.*/\1/" | cut -d: -f1`
  export GUESSED_PROXY_PORT=`wget -O - http://corp.setpac.ge.com/pac.pac --no-proxy 2>/dev/null | grep -i "^var\w* main_proxy" | sed "s/.*\"PROXY\s* \([^\";]*\)\"*;.*/\1/" | cut -d: -f2`
}

commentProxy(){
  if [ -e ~/.bash_profile ] ; then
    echo "Commenting out old proxies in bash_profile"
    sudo sed -i -e '/export http_proxy=/s/^/#/g' ~/.bash_profile
    sudo sed -i -e '/export https_proxy=/s/^/#/g' ~/.bash_profile
    sudo sed -i -e '/export HTTP_PROXY=/s/^/#/g' ~/.bash_profile
    sudo sed -i -e '/export HTTPS_PROXY=/s/^/#/g' ~/.bash_profile
    sudo sed -i -e '/export no_proxy=/s/^/#/g' ~/.bash_profile

    # -----------------------------------------------------
    sudo sed -i -e "/unset http_proxy/d" ~/.bash_profile
    sudo sed -i -e "/unset https_proxy/d" ~/.bash_profile
    sudo sed -i -e "/unset HTTP_PROXY/d" ~/.bash_profile
    sudo sed -i -e "/unset HTTPS_PROXY/d" ~/.bash_profile
    sudo sed -i -e "/unset no_proxy/d" ~/.bash_profile
  fi
}

cleanupBashrc() {
  if [ -e ~/.bash_profile ] ; then
    #echo Cleaning Up bash_profile
    sudo sed -i -e "/export http_proxy=/d" ~/.bash_profile
    sudo sed -i -e "/export https_proxy=/d" ~/.bash_profile
    sudo sed -i -e "/export HTTP_PROXY=/d" ~/.bash_profile
    sudo sed -i -e "/export HTTPS_PROXY=/d" ~/.bash_profile
    sudo sed -i -e "/export no_proxy=/d" ~/.bash_profile

    # ----------------------------------------------------
    sudo sed -i -e "/unset http_proxy/d" ~/.bash_profile
    sudo sed -i -e "/unset https_proxy/d" ~/.bash_profile
    sudo sed -i -e "/unset HTTP_PROXY/d" ~/.bash_profile
    sudo sed -i -e "/unset HTTPS_PROXY/d" ~/.bash_profile
    sudo sed -i -e "/unset no_proxy/d" ~/.bash_profile
  fi
}

disableBashrcProxy() {
  if [ -e ~/.bash_profile ] ; then
    printf "unset http_proxy\nunset https_proxy\nunset HTTP_PROXY\nunset HTTPS_PROXY\nunset no_proxy\n" | sudo tee -a ~/.bash_profile > /dev/null
  else
    echo bash_profile file does not exist. If you want to set environment variables please create a bash_profile file in your root directory.
  fi
}

enableBashrcProxy() {
  if [ -e ~/.bash_profile ] ; then
    printf "export http_proxy=http://$PROXY_AUTH$PROXY_HOST:$PROXY_PORT/\nexport https_proxy=\$http_proxy\nexport HTTP_PROXY=\$http_proxy\nexport HTTPS_PROXY=\$http_proxy\nexport no_proxy=\"127.0.0.1,localhost,localhost.localdomain,.ge.com,*.ge.com,*ge.com\"\n" | sudo tee -a ~/.bash_profile > /dev/null
    source ~/.bash_profile
  else
    echo bash_profile file does not exist. If you want to set environment variables please create a bash_profile file in your root directory.
  fi
}

disableGnomeProxy() {
  gsettings --version >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    gsettings set org.gnome.system.proxy.http host ''
    gsettings set org.gnome.system.proxy.http port 0
    gsettings set org.gnome.system.proxy.http enabled false
    gsettings set org.gnome.system.proxy.https host ''
    gsettings set org.gnome.system.proxy.https port 0
    gsettings set org.gnome.system.proxy.https enabled false
    gsettings set org.gnome.system.proxy mode 'none'
    gsettings list-recursively org.gnome.system.proxy
  fi
}

enableGnomeProxy() {
  gsettings --version >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    gsettings set org.gnome.system.proxy.http host $PROXY_HOST
    gsettings set org.gnome.system.proxy.http port $PROXY_PORT
    gsettings set org.gnome.system.proxy.http enabled true
    gsettings set org.gnome.system.proxy.https host $PROXY_HOST
    gsettings set org.gnome.system.proxy.https port $PROXY_PORT
    gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.1/8', '::1', '.ge.com', '*ge.com']"
    gsettings set org.gnome.system.proxy.https enabled true
    gsettings set org.gnome.system.proxy mode 'manual'
    gsettings list-recursively org.gnome.system.proxy
  fi
}

disableMavenProxy() {
  if [ -e ~/.m2/settings.xml ] ; then
    cp ~/.m2/settings.xml ~/.m2/settings.xml.orig
    xsltproc $ScriptDir/disable-proxy.xsl ~/.m2/settings.xml.orig > ~/.m2/settings.xml.new
    mv -f ~/.m2/settings.xml.new ~/.m2/settings.xml
  else
    echo Maven directory not setup. Could not find settings.xml in directory ./m2
  fi
}

enableMavenProxy() {
  if [ -e ~/.m2/settings.xml ] ; then
    cp ~/.m2/settings.xml ~/.m2/settings.xml.orig
    xsltproc --stringparam proxy-host $PROXY_HOST \
         --stringparam proxy-port $PROXY_PORT \
         --stringparam proxy-username $PROXY_USERNAME \
         --stringparam proxy-password $PROXY_PASSWORD \
         --stringparam noproxy-hosts "127.0.0.1,localhost,localhost.localdomain,.ge.com,*.ge.com, *ge.com" \
         $ScriptDir/enable-proxy.xsl ~/.m2/settings.xml.orig > ~/.m2/settings.xml.new
    mv -f ~/.m2/settings.xml.new ~/.m2/settings.xml
  else
    echo Maven directory not setup. Could not find settings.xml in directory ./m2
  fi
}

fixMavenSettingsFile() {
  sudo chmod 666 ~/.m2/settings.xml.orig
  sudo chmod 666 ~/.m2/settings.xml
  sudo chown root ~/.m2/settings.xml.orig
  sudo chown root ~/.m2/settings.xml
}

enableDockerProxy() {
  sudo mkdir -p /etc/systemd/system/docker.service.d
  sudo touch /etc/systemd/system/docker.service.d/http-proxy.conf
  sudo chmod 777 /etc/systemd/system/docker.service.d/http-proxy.conf
  sudo cat << EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://$PROXY_AUTH$PROXY_HOST:$PROXY_PORT/"
Environment="HTTPS_PROXY=http://$PROXY_AUTH$PROXY_HOST:$PROXY_PORT/"
Environment="NO_PROXY=127.0.0.1,localhost,localhost.localdomain,.ge.com,*.ge.com,*ge.com"
EOF

  sudo cat /etc/systemd/system/docker.service.d/http-proxy.conf

  sudo systemctl daemon-reload

  sudo systemctl restart docker
}

disableDockerProxy() {
  sudo rm -rf /etc/systemd/system/docker.service.d/http-proxy.conf
  sudo systemctl daemon-reload
  sudo systemctl restart docker
}

function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://github.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy.  Please read this tutorial for detailed info about setting your proxy https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1565"
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}

#fixMavenSettingsFile
for arg in $@ ; do
  if [ "$arg" = "--help" ] ; then
    usage
    exit 0
  fi
done

echo "--------------------------------------------------------------"
echo "This script will install tools required for Predix development"
echo "This script runs commands as sudo. If prompted for password,"
echo "You may be asked to provide your password during the installation process"
echo "--------------------------------------------------------------"
echo ""

PROXY_HOST=""
PROXY_PORT="8080"
PROXY_HOST_AND_PORT=""
PROXY_USERNAME="proxyuser"
PROXY_PASSWORD="proxypass"
PROXY_AUTH=""

#Switches
ENABLE=0
DISABLE=0
CLEAN=0

# ------------------------ Yash ---------------------------------
if [ -z "$1" ]; then
  usage
  exit 0
else
  while [ ! -z "$1" ]; do
    [ "$1" == "--enable" ] && ENABLE=1
    [ "$1" == "--disable" ] && DISABLE=1
    [ "$1" == "--clean" ] && CLEAN=1
    shift
  done
fi

if [ $ENABLE -eq 1 ]; then
  # Findig the PAC file and printing out the proxy servers for the user
  echo "Printing configured browser proxies from your pac.pac file"
  AUTOCONFIG="$(scutil --proxy | grep ProxyAutoConfigURL)"
  echo $AUTOCONFIG | cut -d' ' -f 3
  PAC="$(echo $AUTOCONFIG | cut -d' ' -f 3)"
  echo
  curl -s $PAC | grep PROXY
  echo
  echo "Please choose which proxy you want to use and enter it in the command below"
  echo "You may select one of the proxy servers mentioned above or may choose a different one if you know it"
  echo
  read -p "Which proxy do you want to use?  " READ_PROXY
  echo
  PROXY_HOST="$(echo $READ_PROXY | cut -d':' -f 1)"
  PROXY_PORT="$(echo $READ_PROXY | cut -d':' -f 2)"
  echo "Your selected proxy value =" $PROXY_HOST:$PROXY_PORT

  # Enabling or Setting the proxies
  echo "Setting proxy environment variables..."
  commentProxy
  enableBashrcProxy
  echo "done."
  echo
  echo "Setting Apache Maven proxy..."
  enableMavenProxy
  fixMavenSettingsFile
  echo "done."
  echo
fi

if [ $DISABLE -eq 1 ]; then
  echo "Unsetting proxy environment variables..."
  #cleanupBashrc
  disableBashrcProxy
  echo "done."
  echo
  echo "Unsetting Apache Maven proxy..."
  disableMavenProxy
  fixMavenSettingsFile
  echo "done."
  echo
fi

if [ $CLEAN -eq 1 ]; then
  echo "Deleting proxy settings for bash and Maven"
  cleanupBashrc
  #disableGnomeProxy
  disableMavenProxy
  fixMavenSettingsFile
  #disableDockerProxy
fi

echo ""
echo "Open a new terminal window for the changes to take effect"
exit 0