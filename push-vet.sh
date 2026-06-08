cd "$(dirname "$0")"

REPO_USER=stormtheory
REPO=umsl-veteran-center

MY_USER=stormtheory

echo ""

echo " ######### Starting.. PUSH for $REPO ###########"
cd umsl_veteran_center
pwd
#flutter clean
cd ..
git push git@github.com:$REPO_USER/$REPO.git
