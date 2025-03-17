!#/usr/bin/bash

echo "this script will help to set up git!"
echo "it will set your git username and email"
echo "additionally, it will install git, gh, and tig."

echo "installing version control..."
sudo apt install git gh tig --ignore-missing -y
echo "done"

echo "input your email: "
read -p "input your email: " useremail
read -p "input your name: " username

echo "are these details correct?"
echo -e "email: $useremail"
echo -e "name : $username"
read -p "enter to continue" cont

git config --global user.email $useremail
git config --global user.name $username

echo "git is set up!"
