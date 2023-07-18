env=$1;

echo "Copying setup/init into setup/.init_${env}";
cp -r setup/init "setup/.init_${env}";

echo "Running the init for ${env}";
rm -f ".logs/init_${env}.log";
ENV="${env}" make -C "setup/.init_${env}" all > ".logs/init_${env}.log" 2>&1;
STATUS=$?;
rm -rf "setup/.init_${env}";

if [ "$STATUS" -gt 0 ]
then
    echo "An error occured while initializing ${env}.";
    echo "Logs are available in .logs/init_${env}.log";
    exit -1;
fi

rm -f ".logs/init_${env}.log";
echo "Initialization of ${env} ended successfuly.";
