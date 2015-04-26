# BOSH BIND 9 Release
This is a *BOSH* release that can be used to deploy a BIND 9 nameserver.

[BOSH](http://bosh.io/) is a tool that deploys VMs and software.
[ISC](https://www.isc.org/)'s [BIND 9](https://www.isc.org/downloads/BIND/) is a
DNS nameserver.

## How To

### 0. Install BOSH and BOSH CLI
BOSH runs in a special VM which will need to be deployed prior to deploying this BIND release. You will also need to have installed the BOSH CLI on your local workstation (i.e. the *bosh_cli* Ruby gem)

### 1. Target BOSH and login
We assume you're using [BOSH Lite](https://github.com/cloudfoundry/bosh-lite) (*BOSH* under VirtualBox); however, if you have already deployed a *MicroBOSH* or full *BOSH*, then substitute the correct IP address/hostname and credentials below.

Target the IP address (defaults to 192.168.50.4) and log in with the default account and password (admin/admin):

```
bosh target 192.168.50.4
bosh login admin admin
```

### 2. Clone and *cd* to this repo
```
git clone https://github.com/cunnie/bosh-bind-9-release.git
cd bosh-bind-9-release
```

### 3. Download and upload the stemcells to BOSH
```
mkdir stemcells
pushd stemcells
curl -OL https://s3.amazonaws.com/bosh-warden-stemcells/bosh-stemcell-2776-warden-boshlite-centos-go_agent.tgz
popd
bosh upload stemcell stemcells/bosh-stemcell-2776-warden-boshlite-centos-go_agent.tgz
```

### 4. Create and upload the BOSH Release
```
bosh create release --force
    Please enter development release name: bind-9
bosh upload release dev_releases/bind-9/bind-9-0+dev.1.yml
```
If you iterate through several releases, remember to increment the release number when uploading (e.g. "...9-0+dev.2.yml").

### 5. Create Manifest from Example
We copy the manifest template and set its UUID to our BOSH's UUID.

If you're not using *BOSH Lite*, edit the manifest to change the network information and IP addresses:

```
cp examples/bind-9-bosh-lite.yml config/
perl -pi -e "s/PLACEHOLDER-DIRECTOR-UUID/$(bosh status --uuid)/" config/bind-9-bosh-lite.yml
```

### 6. Deploy and Test
If you're not using *BOSH Lite*, then substite the correct IP address when you use the *nslookup* command. The IP address is available from your deployment manifest or by typing `bosh vms`.

```
bosh deployment config/bind-9-bosh-lite.yml
bosh -n deploy
# if you're using BOSH Lite, you'll probably need
# to add a route similar to something like this
sudo route add -net 10.244.0.0/24 192.168.50.4
#  attempt the lookup
nslookup google.com 10.244.0.66
```

### Bugs

The example deployment manifests do not include a persistent store; In other words, it would be reasonable to use this release to deploy a secondary or caching-only nameserver, but not a primary nameserver.

The configuration in the example deployment manifest allows recursive requests from anywhere, technically an "Open DNS Resolver". This allows the deployed nameserver to be used in a Distributed Denial of Service attack using [DNS Amplification](https://blog.cloudflare.com/deep-inside-a-dns-amplification-ddos-attack/). Please modify the manifest to exclude recursive queries before deploying the nameserver to the Internet at large.
