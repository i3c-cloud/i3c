
if [ "x$i3cSshPass" == "x" ]; then
	i3cSshPass='';
fi	

echo "i3cSshPass:$i3cSshPass"

#-p 8022:8022
#-e VIRTUAL_PORT=8022 \
#-p 2222:22
dParams="-d -p 2222:22 $addParams \
  -e VIRTUAL_PORT=80 \
	-e FILTERS={\"name\":[\"^/i3c$\"]} -e AUTH_MECHANISM=cAuth \
	-e AUTH_USER=i3c -e AUTH_PASSWORD=$i3cSshPass \
	"
addIParams=true;
	