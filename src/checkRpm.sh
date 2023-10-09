yum -q check-update $(rpm -qg SAS --qf '%{NAME} ')

yum -q list installed $(rpm -qg SAS --qf '%{NAME} ')

rpm -qa --last

yum grouplist

rpm -qg SAS --qf '%{NAME}\n' | grep -vi "not contain"

rpm -qf --qf '::%{group}::%{name}\n' /etc/yum.repos.d/*.repo

rpm -qa --last | grep "sas-" | grep rabbit

yum repolist all
