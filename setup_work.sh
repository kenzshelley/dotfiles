# Install gcloud
curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-272.0.0-darwin-x86_64.tar.gz > google-cloud-sdk.tar.gz
tar -xvf google-cloud-sdk.tar.gz
mv google-cloud-sdk ~/Development/
./$HOME/Development/google-cloud-sdk/install.sh
./$HOME/Development/google-cloud-sdk/bin/gcloud init
rm -r ~/Development/google-cloud-sdk.tar.gz 

# setup google application default creds
gcloud auth application-default login
export GOOGLE_APPLICATION_CREDENTIALS=/Users/mshelley/.config/gcloud/application_default_credentials.json

# Setup docker
docker-machine create --driver virtualbox default
