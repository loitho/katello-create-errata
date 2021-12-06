FROM nginx:mainline-alpine

LABEL creator Thomas HERBIN

ARG S3_URI

RUN   apk add --no-cache \
        python3 \
        py3-pip \
        py3-six \
        wget \
        && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
          createrepo_c \
      && pip3 install --no-cache-dir --upgrade pip \
      && pip3 install --no-cache-dir \
        awscli \
      && rm -rf /var/cache/apk/* ;

WORKDIR /tmp

COPY generate_updateinfo.py /tmp
COPY nginx-repo.conf /etc/nginx/conf.d/default.conf

## Create Repo directories and remove index file to browse the server files freely
RUN mkdir /usr/share/nginx/html/errata5 \
          /usr/share/nginx/html/errata6 \
          /usr/share/nginx/html/errata7 \
          /usr/share/nginx/html/errata8 \
   && rm /usr/share/nginx/html/index.html

## Create Repo metadata
RUN createrepo_c -v /usr/share/nginx/html/errata5 \
 && createrepo_c -v /usr/share/nginx/html/errata6 \
 && createrepo_c -v /usr/share/nginx/html/errata7 \
 && createrepo_c -v /usr/share/nginx/html/errata8

## Get the errata file from CEFS, check the sha1sum and convert the file to compatible "yum repository" updateinfo.xml files
## Then we put the file in the repository
RUN wget http://cefs.steve-meier.de/errata.latest.xml.bz2 \
 && wget -qO- http://cefs.steve-meier.de/errata.latest.sha1 | grep bz2 > check.sha1 && sha1sum -c check.sha1 \
 && bzip2 -dc errata.latest.xml.bz2 > errata.latest.xml \
 && ./generate_updateinfo.py -s all -t all -v -d ./ errata.latest.xml \
 && rm -rf errata.latest.xml* \
								      \
 && mv /tmp/updateinfo-5/updateinfo.xml /usr/share/nginx/html/errata5/repodata/ \
 && mv /tmp/updateinfo-6/updateinfo.xml /usr/share/nginx/html/errata6/repodata/ \
 && mv /tmp/updateinfo-7/updateinfo.xml /usr/share/nginx/html/errata7/repodata/ \
 && mv /tmp/updateinfo-8/updateinfo.xml /usr/share/nginx/html/errata8/repodata/

## Tell the repository that it now contains errata
RUN modifyrepo_c /usr/share/nginx/html/errata5/repodata/updateinfo.xml /usr/share/nginx/html/errata5/repodata \
 && modifyrepo_c /usr/share/nginx/html/errata6/repodata/updateinfo.xml /usr/share/nginx/html/errata6/repodata \
 && modifyrepo_c /usr/share/nginx/html/errata7/repodata/updateinfo.xml /usr/share/nginx/html/errata7/repodata \
 && modifyrepo_c /usr/share/nginx/html/errata8/repodata/updateinfo.xml /usr/share/nginx/html/errata8/repodata 

## Exit if no bucket is provided
## If you wish to run this container as the nginx server, you can comment everything below
RUN echo "checking S3 Bucket" && \
  if [ -z "${S3_URI}" ]; \
  then \
    echo "missing ENV Variable : S3_URI" \
    && echo "you should provide the S3_URI in the form : S3_URI=s3://yourbucket/" \
    && exit 1; \
  fi

RUN echo "retrieving config file from URI ${S3_URI}" \
    && aws s3 cp /usr/share/nginx/html ${S3_URI} --recursive

