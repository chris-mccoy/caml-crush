# Build with    : docker build . -t caml-crush
# Run with, e.g.: docker run --rm -it --device /dev/bus/usb/001/018 caml-crush
# Bug: Need to run pcscd manually inside the container
FROM centos:7
MAINTAINER chris@chr.is
RUN yum group install "Development Tools" -y && yum install -y epel-release && yum install -y git patch unzip wget which pcre-devel python-devel openssl gnutls-devel openssl-devel opensc pcsc-lite-devel gengetopt help2man vim-enhanced python-pip
RUN wget https://raw.github.com/ocaml/opam/master/shell/opam_installer.sh -O - | sh -s /usr/local/bin && /usr/local/bin/opam init --comp 4.02.1 --auto-setup --root=/opt/opam
# Tested with these versions on OPAM
RUN eval `opam config env --root=/opt/opam` && opam install -y pcre 'parmap=1.0-rc7.1' 'ocaml-xml-rpc=0.2.3' 'coccinelle=1.0.2' 'ocamlnet=3.7.7' 'camlidl=1.05' 'config-file=1.2' 'ssl=0.5.3'
# Hack - caml-crush expects camlidl to be in the system libraries.  Doesn't use ocamlfind with opam
RUN eval `opam config env --root=/opt/opam` && cp $(ocamlfind query camlidl)/libcamlidl.a /usr/local/lib64 && cp -r $(ocamlfind query camlidl)/caml /usr/local/include && mkdir -p /opt/src/caml-crush && git clone -n https://github.com/ANSSI-FR/caml-crush.git /opt/src/caml-crush && cd /opt/src/caml-crush && git checkout 39ee34fa2beeb0bfabb92f376f052013617c0d24 && ./autogen.sh && ./configure --libdir=/usr/local/lib64 --with-idlgen --with-rpcgen --with-ssl --with-ssl-clientfiles=env --with-gnutls && make && make install
RUN cp /usr/local/etc/pkcs11proxyd/pkcs11proxyd.conf /root && cp /usr/local/lib64/caml-crush/libp11client.so /root 
RUN cd /root && git clone https://github.com/Yubico/yubico-piv-tool.git && cd yubico-piv-tool && autoreconf --install && ./configure && make
RUN pip install -U pip && pip install yubikey-manager
ENTRYPOINT /bin/bash
