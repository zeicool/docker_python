
FROM ubuntu:14.04

#设置时间和语言环境变量
ENV TZ Asia/Shanghai
ENV LANG zh_CN.UTF-8

#更换阿里云源
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak\
	&& echo 'deb http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse' > /etc/apt/sources.list\
	&& echo 'deb http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse' >> /etc/apt/sources.list\
	&& echo 'deb http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse' >> /etc/apt/sources.list\
	&& echo 'deb http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse' >> /etc/apt/sources.list\
	&& echo 'deb http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse' >> /etc/apt/sources.list\
	&& echo 'deb-src http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse' >> /etc/apt/sources.list\
	&& echo 'deb-src http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse' >> /etc/apt/sources.list\
	&& echo 'deb-src http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse' >> /etc/apt/sources.list\
	&& echo 'deb-src http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse' >> /etc/apt/sources.list\
	&& echo 'deb-src http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse' >> /etc/apt/sources.list\
	&& apt-get update

#安装ssh server进行远程操控
# 设置root ssh远程登录密码
# 容器需要开放SSH 22端口，以使外部能够访问容器内部
RUN mkdir /var/run/sshd\
	&& apt-get install -y openssh-server\
	&& echo "root:root" | chpasswd\
	&& sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config\
	&& sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
EXPOSE 22

#常用安装
#软件冲突，要先将vim-common卸载，再装vim
RUN apt-get remove -y vim-common && apt-get install -y vim curl make g++ git wget libbz2-dev libssl-dev libreadline6 libreadline6-dev libsqlite3-dev

#添加 python用户
RUN useradd --create-home --no-log-init --shell /bin/bash python\
	&& echo 'python:python' | chpasswd\
	&& chmod u+w /etc/sudoers\
	&& echo 'python ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers\
	&& chmod u-w /etc/sudoers

USER python
WORKDIR /home/python

RUN curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash\
	&& echo 'export PATH="/home/python/.pyenv/bin:$PATH"' >> ~/.bashrc\
	&& echo 'eval "$(pyenv init -)"' >> ~/.bashrc\
	&& echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc\
	&& /bin/bash -c "source ~/.bashrc"

RUN /home/python/.pyenv/bin/pyenv install 2.7.14 -v\
	&& /home/python/.pyenv/bin/pyenv install 3.6.4 -v\
	&& /home/python/.pyenv/bin/pyenv rehash\
	&& /home/python/.pyenv/bin/pyenv virtualenv 2.7.14 my2714\
	&& /home/python/.pyenv/bin/pyenv local 2.7.14\
	&& mkdir ~/.pip\
	&& touch ~/.pip/pip.conf\
	&& echo '[global]' >> ~/.pip/pip.conf\
	&& echo 'index-url=https://mirrors.aliyun.com/pypi/simple/' >> ~/.pip/pip.conf\
	&& echo 'trusted-host=mirrors.aliyun.com' >> ~/.pip/pip.conf\
	&& /home/python/.pyenv/versions/2.7.14/bin/pip install jupyter

#pip安装python3拓展包（有的只能pip安装）
#ADD requirements.txt /tmp/requirements.txt
#RUN pip3 install -r /tmp/requirements.txt
USER root
#安装PyQt4
RUN apt-get install -y libxext6 libxext-dev libqt4-dev libqt4-gui libqt4-sql\
	&& apt-get install -y qt4-dev-tools qt4-doc qt4-qtconfig qt4-demos qt4-designer\
	&& apt-get install -y python-qt4\
	&& apt-get install -y python-qt4-*\
	&& apt-get install -y python-qscintilla2\
	&& apt-get install -y python3-pyqt4\
	&& apt-get install -y python3-pyqt4.qsci\
	&& apt-get install -y python3-pyqt4.qtsql\
	&& apt-get install -y python3-pyqt4.phonon

CMD ["/usr/sbin/sshd", "-D"]