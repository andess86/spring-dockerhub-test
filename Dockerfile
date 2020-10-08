FROM maven:3.6.3-jdk-11-slim AS build
RUN mkdir -p /workspace
WORKDIR /workspace
COPY pom.xml /workspace
COPY src /workspace/src
RUN mvn -B -f pom.xml clean package -DskipTests 



FROM openjdk:11-jdk-slim
COPY --from=build /workspace/target/*.jar /usr/local/bin/app.jar

RUN apt-get update \
    && apt-get install -y openssh-server \
    && mkdir -p /var/run/sshd 
	

RUN apt install -y dos2unix supervisor \
	&& mkdir -p /var/log/supervisor

RUN echo 'root:atlas-domain-server' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN dos2unix /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /etc/supervisor/conf.d/supervisord.conf


CMD ["/usr/bin/supervisord"]