# Foreman/Katello Create Errata

Create RPM repository containing Errata for Foreman to sync and provide to clients

## How to use 

- Provide an S3_URI in the form at build time: `S3_URI=s3://yourbucket/` 
  - When the docker image is being built it will upload the generated errata files into the specified S3 Bucket, you can then use the S3 HTTPS URL as the repository URL for Katello
- OR You can also comment the end of the file and when you spawn a container from the image, you'll have a webserver providing yum repositories for EL 5/6/7/8 under the "errata5/6/7/8" folder

## What

This tool is a way to create a repository containing Errata for CentOS 7
Foreman/Katello can then read and sync this repository to provide errata information to all of its clients

This is heavily based on 2 opensource projects : 
- CEFS project [http://cefs.steve-meier.de] 
- https://github.com/vmfarms/generate_updateinfo

The first provides for free Errata information about CentOS packages
The second makes us able to transform the XML provided by CEFS into a an updateinfo.xml file usable by a YUM repository

This then upload to an S3 bucket specified with `S3_URI` env variable

## Manual Build instruction 

```
git clone https://github.com/loitho/katello-create-errata.git
cd katello-create-errata
```

### If you're behind a proxy

```
docker build --build-arg HTTP_PROXY=http://xxxxxx:8080  \
             --build-arg HTTPS_PROXY=http://xxxxxx:8080 \
             --build-arg http_proxy=http://xxxxx:8080 \
             --build-arg https_proxy=http://xxxxxx:8080 \
             --build-arg NO_PROXY="localhost,127.0.0.1,169.254.169.254,10.0.0.0/8,172.16.0.0/12,.internal,.svc,.amazonaws.com" \
             --build-arg no_proxy="localhost,127.0.0.1,169.254.169.254,10.0.0.0/8,172.16.0.0/12,.internal,.svc,.amazonaws.com" \
             --build-arg S3_URI="s3://yourrepository" .
```
### If you're not using a proxy : 
```
docker build --build-arg S3_URI="s3://yourrepository" .
```

## How to run as webserver

The image is based on an Alpine Nginx, when running the image with : 
`docker run -p8080:80 -it <build ID>`
you can use a web brower to see 4 repository : 
- <yourserver>:<port>/errata5
- <yourserver>:<port>/errata6
- <yourserver>:<port>/errata7
- <yourserver>:<port>/errata8
Which provides errata for the 5 major releases of CentOS
You can then simply add those URL to Katello as yum repositories
