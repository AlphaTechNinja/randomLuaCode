--this library handles using wireless network cards
local component = require("component")
local alert = require("gui").alert
local event = require("event")
local modem = component.list("modem")()
if not modem then alert("missing wireless network card!") return end
modem = component.proxy(modem)
--configs
local configs = {}
configs.defaultPort = 1000
--main
local net = setmetatable({},{__index = modem})
net.query = {}
net.avaibleHosts = {}
function net.host(nick)
if not net.hosting then
net.hosting = true
net.nickName = nick
return true
else
return false,"already hosting"
end
end
function net.scan(port)
net.broadcast(port,"SCAN")
end
function net.unHost()
net.hosting = false
net.broadcast(1000,"UNHOST")
end
function net.getAddress()
return modem.address
end
function net.request(address,port,...)
net.send(address,port,"ONP",...)
local result = {net.next(address,port,10)}
if result[1] == false then
return false,"access denied"
else
return table.unpack(result)
end
end
--ughhhh i hate this part
function net.next(address,port,timeout)
local deadline = computer.uptime() + timeout or math.huge
while true do
for i,v in ipairs(net.query) do
if (v.port == port or not port) and (v.address == address or not address) then
return table.remove(net.query,i)
end
end
event.sleep(0.05)
if computer.uptime() > deadline then
return false,"timeout"
end
end
end
--attach event handler
net.handle = event.addHandler(function (env,_,address,port,_,msg,...)
if msg == "ONP" then
table.insert(net.query,{address = address,port = port,data = {...}})
elseif msg == "SCAN" and net.hosting then
net.send(address,port,"HOST",net.nickName)
elseif msg == "HOST" then
for i,v in ipairs(net.avaibleHosts) do
if v.address == address then
return
end
end
table.insert(net.avaibleHosts,{address = address,name = select(1,...)})
elseif msg == "UNHOST" then
for i,v in ipairs(net.avaibleHosts) do
if v.address == address then
table.remove(net.avaibleHosts,i)
end
end
end
end
)
net.kill = function () event.removeHandler(net.handle) end
return net
