#!/bin/bash

# ubuntu theme?, pycharm

###################################################################

if [ ! -d /tmp/setupUbuntu ]; then
	sudo mkdir /tmp/setupUbuntu
fi
TMP="/tmp/setupUbuntu"
USER=""
HOMEDIR=""
TODO=""

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -u|--user)
    USER="$2"
    shift # past argument
    shift # past value
    ;;
    *)
    shift
    ;;
esac
done

if [ "$USER" == "" ]; then
        echo "No user given. Supply username with -u or --user"
        exit 1
else
        HOMEDIR="/home/$USER"
        echo "Got user $USER with home directory $HOMEDIR"
fi

function install_basics {
        sudo apt-get install curl wget openssh-server git unity-tweak-tool unzip -y
        sudo chown -R $USER $HOMEDIR/.gitconfig
        git config --global alias.lol "log --pretty=oneline --abbrev-commit --graph --decorate --all"
}

if [ ! -f $HOMEDIR/.setupUbuntu.tmp ]; then
	echo "Do you want to update/upgrade your system first? [Y/n]"
	REPLY="Y"
        read REPLY
        if [[ $REPLY == "Y"  ]] || [[ $REPLY == ""  ]]; then
	        sudo apt-get update -y
		sudo apt-get upgrade -y
		install_basics
		touch $HOMEDIR/.setupUbuntu.tmp
        fi
fi


###################################################################

function install_zsh {
	sudo apt-get install zsh -y
        #sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
        cd $TMP
        if [ ! -d $TMP/ubuntuSetup ]; then
                git clone https://github.com/sschwebler/ubuntuSetup.git
        fi
        cd $HOMEDIR
        sudo chmod +x $TMP/ubuntuSetup/installZsh.sh
        sudo $TMP/ubuntuSetup/installZsh.sh
	sudo chown -R $USER $HOMEDIR/.oh-my-zsh
        sudo chown $USER $HOMEDIR/.*zsh*
	chsh -s $(which zsh)
}

function install_powerlevel {
	if [ ! -d $HOMEDIR/.oh-my-zsh ]; then
		echo "Oh-my-zsh is not installed"
                echo "Do you want to install zsh? [Y/n]"
                REPLY="Y"
                read REPLY
                if [[ $REPLY == "Y"  ]] || [[ $REPLY == ""  ]]; then
                        install_zsh
		fi
	fi
	sudo git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/themes/powerlevel9k
        echo "backup zshrc"
        cp .zshrc .zshrc.bck
        cd $TMP
        if [ ! -d $TMP/ubuntuSetup ]; then
                git clone https://github.com/sschwebler/ubuntuSetup.git
        fi
        cd ubuntuSetup/powerlevel
        sudo cp zshrc $HOMEDIR/.zshrc
        sudo cp icons.zsh $HOMEDIR/.oh-my-zsh/themes/powerlevel9k/functions
        cd $TMP
        sudo git clone https://github.com/ryanoasis/nerd-fonts
        cd nerd-fonts
        sudo ./install.sh
        cd $HOMEDIR
        sed -i -e 's/robbyrussell/powerlevel9k\/powerlevel9k/g' .zshrc
        sed -i -e "s/simon/$USER/g" .zshrc
        sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

	gconftool-2 --set /apps/gnome-terminal/profiles/Default/font --type string "DejaVuSansMono Nerd Font Book 13"
        TODO="$TODO"$'\n-) Set the terminal font to "DejaVuSansMono Nerd Font" size "11"'
	sudo chown -R $USER $HOMEDIR/.oh-my-zsh
	sudo chown $USER $HOMEDIR/.*zsh*
}

function install_intellij {
        echo "Installing intelij..."
	# Prerequisites
	sudo apt install libxml-xpath-perl -y
	cd $TMP
	wget https://www.jetbrains.com/updates/updates.xml -O updates.xml
	tail -n +2 updates.xml > updates2.xml

	# Get highest version
	xpath -q -e "/products/product/channel[contains(@name, 'IntelliJ IDEA ') and contains(@status, 'release')]/build/@version" updates2.xml > versions
	arr=()
	while IFS='' read -r line || [[ -n "$line" ]]; do
	    arr+=("$line")
	done < "versions"
	versions=()
	for i in "${arr[@]}"
	do
	   tmp=$(echo "$i" | cut -f2 -d=)
	   tmp=$(echo ${tmp::-1} | cut -c 2-)
	   versions+=("${tmp//.}")
	done
	max=${versions[0]}
	for n in "${versions[@]}" ; do
	    ((n > max)) && max=$n
	done
	version=${max:0:4}.${max:4:1}.${max:5:1}

	# Download and install IntelliJ
	wget "https://download.jetbrains.com/idea/ideaIU-$version.tar.gz" -O ideaIU.tar.gz
	sudo tar xfz ideaIU.tar.gz -C /opt/
	sudo mv /opt/idea-IU* /opt/ideaIU
	sudo chown $USER -R /opt/ideaIU
	/opt/ideaIU/bin/idea.sh &
	cd $TMP
}

function install_telegram {
        echo "Installing telegram..."
	sudo add-apt-repository -y 'ppa:atareao/telegram'
	sudo apt-get update
	sudo apt-get install telegram -y
	sudo ln -s /opt/telegram/Telegram /bin/telegram
#	telegram &
	cd /tmp
	socket="$(ls /tmp | grep '{*}')"
	sudo chmod $USER:$USER $socket
	cd $HOMEDIR
	sudo chmod -R $USER:$USER .local/share/TelegramDesktop
}

function install_phpstorm {
        echo "Install phpstorm"
}

function install_postman {
        echo "Installing postman..."
	cd $TMP
	wget https://dl.pstmn.io/download/latest/linux64 -O postman.tar.gz
	sudo tar -xzf postman.tar.gz -C /opt
	sudo rm postman.tar.gz
	sudo ln -s /opt/Postman/Postman /usr/bin/postman
	cat > ~/.local/share/applications/postman.desktop <<EOL
[Desktop Entry]
Encoding=UTF-8
Name=Postman
Exec=postman
Icon=/opt/Postman/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;
EOL
	postman &
}

function install_chromium {
	echo "Installing chromium..."
	sudo apt-get install chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg -y
	sudo apt-get install chromium-codecs-ffmpeg-extra -y
}

function install_shutter {
	echo "Installing shutter..."
	sudo apt-get install shutter -y
}

function install_ccsm {
	echo "Installing ccsm..."
	sudo apt-get install compizconfig-settings-manager compiz-plugins-extra -y
	ccsm &
}

function install_virtualbox {
	echo "Installing VirtualBox..."
	sudo apt-get install virtualbox virtualbox-qt virtualbox-dkms -y
	virtualbox &
}

function install_docker {
	echo "Installing docker..."
	sudo apt-get remove docker docker-engine docker.io -y
	sudo apt-get install \
	    apt-transport-https \
	    ca-certificates \
	    curl \
	    software-properties-common -y
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo apt-key fingerprint 0EBFCD88 -y
	sudo add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	   stable" -y
	sudo apt-get update
	sudo apt-get install docker-ce -y
	sudo usermod -aG docker $USER
}

function install_dockercompose {
	docker --version
	if [ $? != 0 ]; then
		echo "Docker is not installed"
                echo "Do you want to install docker first? [Y/n]"
                REPLY="Y"
                read REPLY
                if [[ $REPLY == "Y"  ]] || [[ $REPLY == ""  ]]; then
                        install_docker
                fi
	fi
	echo "Installing docker-compose..."
	sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	sudo mkdir -p ~/.zsh/completion
	curl -L https://raw.githubusercontent.com/docker/compose/1.18.0/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose
#	echo "fpath=(~/.zsh/completion $fpath)" >> $HOMEDIR/.zshrc
#	echo "autoload -Uz compinit && compinit -i" >> $HOMEDIR/.zshrc
}

function install_kvm {
	echo "Installing kvm..."
	sudo apt-get install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils -y
	sudo apt-get install virt-manager -y
}

function install_latex {
	echo "Installing texlive, texstudio..."
	sudo apt-get install texlive-full -y
	sudo apt-get install texstudio -y
}

function install_slack {
	echo "Installing slack..."
	sudo apt-add-repository ppa:rael-gc/scudcloud -y
	sudo apt update && sudo apt install scudcloud -y
	scudcloud &
}

function install_skype {
	echo "Installing Skpye..."
	cd $TMP
	wget https://go.skype.com/skypeforlinux-64.deb -O skype.deb
	sudo dpkg -i skype.deb
}

function install_java {
	echo "Installing Java..."
	sudo apt-get install openjdk-8-jdk
}

function install_maven {
	echo "Installing Maven..."
	sudo apt-get install maven
}

function install_conky {
	echo "Installing Conky..."
	sudo apt-get install conky -y
	sudo apt-get install conky-all -y
	cd $TMP
        if [ ! -d $TMP/ubuntuSetup ]; then
                git clone https://github.com/sschwebler/ubuntuSetup.git
        fi
	cd ubuntuSetup/conky
	sudo cp .conkyrc $HOMEDIR
	sudo cp -R .conky $HOMEDIR
	sudo chown $USER $HOMEDIR/.conkyrc
	sudo chown -R $USER $HOMEDIR/.conkyrc
}

function install_node {
	echo "Installing Node..."
	sudo apt-get install node npm -y
	sudo npm cache clean -f
	sudo npm install -g n
	sudo n stable
	sudo ln -sf /usr/local/n/versions/node/*/bin/node /usr/bin/nodejs
}

function install_theme {
	cd $HOMEDIR
	mkdir .themes
	cd $TMP
	wget https://github.com/anmoljagetia/Flatabulous/archive/master.zip -O flat.zip
	unzip flat.zip -d $HOMEDIR/.themes
	sudo add-apt-repository ppa:noobslab/icons -y
	sudo apt-get update
	sudo apt-get install ultra-flat-icons -y
}

function install_all {
	install_basics
	install_zsh
	install_powerlevel
	install_intellij
	install_telegram
	install_phpstorm
	install_postman
	install_chromium
	isntall_shutter
	install_ccsm
	install_virtualbox
	install_docker
	install_dockercompose
	install_kvm
#	install_latex
	install_slack
	install_skype
	install_java
	install_maven
	install_conky
	install_node
	install_theme
	exit 0
}

all_done=0
while (( !all_done )); do
        options=("Install all" "Install ZSH" "Install Powerlevel" "Install IntelliJ" "Install Telegram" "Install Php Storm" "Install Postman" "Install Chromium" "Install Shutter" "Install CCSM" "Install Virtual Box" "Install docker" "Install docker-compose" "Install kvm" "Install Latex" "Install Slack" "Install Skype" "Install Java" "Install Conky" "Install Node" "Install Flatabulous Theme" "Quit")

        echo "Choose an option:"
        select opt in "${options[@]}"; do
                case $REPLY in
			1) install_all; break ;;
			2) install_zsh; break ;;
			3) install_powerlevel; break;;
                        4) install_intellij; break ;;
                        5) install_telegram; break ;;
			6) install_phpstorm; break ;;
			7) install_postman; break ;;
			8) install_chromium; break ;;
			9) install_shutter; break ;;
			10) install_ccsm; break ;;
			11) install_virtualbox; break ;;
			12) install_docker; break ;;
			13) install_dockercompose; break ;;
			14) install_kvm; break ;;
			15) install_latex; break ;;
			16) install_slack; break ;;
			17) install_skype; break ;;
			18) install_java; break ;;
			19) install_conky; break ;;
			20) install_node; break ;;
			21) install_theme; break ;;
			22) echo "$TODO"; all_done=1; break ;;
                        *) echo "What's that?" ;;
                esac
        done
done
