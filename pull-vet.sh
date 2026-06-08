cd "$(dirname "$0")"
WD="$PWD"
echo "$WD"

# No running as root!
ID=$(id -u)
if [ "$ID" == '0'  ];then
        echo "Not safe to run as root... exiting..."
        exit
fi

cd ..
REPO_USER=stormtheory
REPO=umsl-veteran-center


MY_USER=stormtheory
BRANCH_NAME=Perfect_Storm

if [ -d $REPO ];then
    
    cd $REPO
    TEST=$(git log origin/HEAD..HEAD --oneline|wc -l)
    cd -
    if [ "$TEST" -gt 0 ]; then
        echo "";echo "##########################################"
        echo "  WARNING!!!! Commited but not pushed."
        echo "##########################################";echo ""
            read -p " NOT COMMITED PACKAGES, continue? $REPO [y] > " ANS
            if [ "$ANS" != y ];then
                exit
            fi
    fi
    cd "$(dirname "$0")"
    read -p " Are you sure you want to remove and re-clone $REPO [y] > " ANS
    if [ "$ANS" == y ];then
            #if [ ! -d ./safe-lib ];then
                cd "$(dirname "$0")"
                mv $REPO/lib ./safe-lib
            #fi
        rm -rf $REPO
    else
        exit
    fi
fi

echo ""
echo " ######### Starting.. for $REPO ###########"
umask 022
git clone git@github.com:$REPO_USER/$REPO.git
#git clone https://github.com/$REPO_USER/$REPO.git
cd $REPO
#git fetch https://github.com/$REPO_USER/$REPO.git
git fetch git@github.com:$REPO_USER/$REPO.git
if git branch -a|grep --color "$BRANCH_NAME";then
    echo "Checkout $BRANCH_NAME"
    git checkout "$BRANCH_NAME"
else
    echo "Make new Branching: $BRANCH_NAME"
    git checkout -b "$BRANCH_NAME"
fi

cd $WD
echo "$WD"
ls
#cp -rvf ./safe-lib/* $REPO/lib/
