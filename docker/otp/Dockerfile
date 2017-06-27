FROM java:openjdk-8-jre

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ARG OTP_VERSION 
ENV OTP_VERSION ${OTP_VERSION:-1.0.0}

ENV OTP /srv/otp/otp-${OTP_VERSION}-shaded.jar

RUN mkdir -p $(dirname ${OTP}) && wget http://maven.conveyal.com.s3.amazonaws.com/org/opentripplanner/otp/${OTP_VERSION}/otp-${OTP_VERSION}-shaded.jar -O ${OTP}

COPY otp-start.sh /usr/bin/otp-start.sh
RUN chmod +x /usr/bin/otp-start.sh

EXPOSE 7000

VOLUME /srv/otp/data

WORKDIR /

ENTRYPOINT [ "/usr/bin/otp-start.sh" ]
