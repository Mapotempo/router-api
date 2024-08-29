FROM openjdk:8

ARG OTP_VERSION
ENV OTP_VERSION ${OTP_VERSION:-1.5.0}

ENV OTP /srv/otp/otp-${OTP_VERSION}-shaded.jar

RUN mkdir -p $(dirname ${OTP}) && wget https://repo1.maven.org/maven2/org/opentripplanner/otp/${OTP_VERSION}/otp-${OTP_VERSION}-shaded.jar -O ${OTP}

# Install needed packages
RUN apt update ; apt upgrade -y && \
    apt-get install -y make osmosis unzip jq

# Cleanup Debian packages
RUN apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

COPY otp-start.sh /usr/bin/otp-start.sh
RUN chmod +x /usr/bin/otp-start.sh

EXPOSE 7000

VOLUME /srv/otp/data

WORKDIR /

ENTRYPOINT [ "/usr/bin/otp-start.sh" ]
