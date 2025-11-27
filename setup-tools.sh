#!/bin/bash
set -e

echo ">>> Installing Timoni..."
# Download Timoni (latest version)
TIMONI_VERSION="0.23.0"
curl -sL "https://github.com/stefanprodan/timoni/releases/download/v${TIMONI_VERSION}/timoni_${TIMONI_VERSION}_linux_amd64.tar.gz" | tar xz
chmod +x timoni
sudo mv timoni /usr/local/bin/
echo "Timoni installed: $(timoni version)"

echo ">>> Installing KubeVela CLI..."
# Download KubeVela CLI
curl -fsSl https://kubevela.io/script/install.sh | bash
echo "KubeVela installed: $(vela version)"

echo ">>> Setup Complete!"
