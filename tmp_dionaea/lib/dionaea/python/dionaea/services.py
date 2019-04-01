#********************************************************************************
#*                               Dionaea
#*                           - catches bugs -
#*
#*
#*
#* Copyright (C) 2009  Paul Baecher & Markus Koetter
#* 
#* This program is free software; you can redistribute it and/or
#* modify it under the terms of the GNU General Public License
#* as published by the Free Software Foundation; either version 2
#* of the License, or (at your option) any later version.
#* 
#* This program is distributed in the hope that it will be useful,
#* but WITHOUT ANY WARRANTY; without even the implied warranty of
#* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#* GNU General Public License for more details.
#* 
#* You should have received a copy of the GNU General Public License
#* along with this program; if not, write to the Free Software
#* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#* 
#* 
#*             contact nepenthesdev@gmail.com  
#*
#*******************************************************************************/


import imp
import logging
import sys
import traceback
import fnmatch

from dionaea.core import g_dionaea, ihandler
import tempfile

# service imports
import dionaea.http
import dionaea.tftp
import dionaea.ftp
import dionaea.mirror
from dionaea.smb import smb
import dionaea.sip
from dionaea.mssql import mssql
from dionaea.mysql import mysql
from dionaea.pptp import pptp
from dionaea.mqtt import mqtt
from dionaea.upnp import upnp

logger = logging.getLogger('services')

# reload service imports
#imp.reload(dionaea.http)
#imp.reload(dionaea.tftp)
#imp.reload(dionaea.smb)

# global slave
# keeps track of running services (daemons)
# able to restart them
global g_slave
global addrs

class slave():
	def __init__(self):
		self.services = []
		self.daemons = {}

	def start(self, addrs):
		print("STARTING SERVICES")
		try:
			for iface in addrs:
				print(iface)
				for addr in addrs[iface]:
					print(addr)
					self.daemons[addr] = {}
					for service in self.services:
						print(service)
						if not service in self.daemons[addr]:
							self.daemons[addr][service] = []
						daemon = service.start(service, addr, iface=iface)
						self.daemons[addr][service].append(daemon)
		except Exception as e:
			raise e
		print(self.daemons)

# for netlink, 
# allows listening on new addrs
# and discarding listeners on closed addrs
class nlslave(ihandler):
	def __init__(self):
		ihandler.__init__(self, "dionaea.*.addr.*")
		self.services = []
		self.daemons = {}
	def handle_incident(self, icd):
		print("SERVANT!\n")
		addr = icd.get("addr")
		iface = icd.get("iface")
		for i in self.ifaces:
			print("iface:{} pattern:{}".format(iface,i))
			if fnmatch.fnmatch(iface, i):
				if icd.origin == "dionaea.module.nl.addr.new" or "dionaea.module.nl.addr.hup":
					self.daemons[addr] = {}
					for s in self.services:
						self.daemons[addr][s] = []
						d = s.start(s, addr, iface=iface)
						self.daemons[addr][s].append(d)
				if icd.origin == "dionaea.module.nl.addr.del":
					print(icd.origin)
					for s in self.daemons[addr]:
						for d in self.daemons[addr][s]:
							s.stop(s, d)
				break

	def start(self, addrs):
		pass

class service:
	def start(self, addr, iface=None):
		raise NotImplementedError("do it")
	def stop(self, daemon):
		raise NotImplementedError("do it")

class httpservice(service):
	def start(self, addr, iface=None):
		daemon = dionaea.http.httpd(proto='tcp')
		daemon.bind(addr, 80, iface=iface)
		daemon.chroot(g_dionaea.config()['modules']['python']['http']['root'])
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()

class httpsservice(service):
	def start(self, addr, iface=None):
		daemon = dionaea.http.httpd(proto='tls')
		daemon.bind(addr, 443, iface=iface)
		daemon.chroot(g_dionaea.config()['modules']['python']['http']['root'])
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()


class ftpservice(service):
	def start(self, addr,  iface=None):
		daemon = dionaea.ftp.ftpd()
		daemon.chroot(g_dionaea.config()['modules']['python']['ftp']['root'])
		daemon.bind(addr, 21, iface=iface)
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()


class tftpservice(service):
	def start(self, addr,  iface=None):
		daemon = dionaea.tftp.TftpServer()
		daemon.chroot(g_dionaea.config()['modules']['python']['tftp']['root'])
		daemon.bind(addr, 69, iface=iface)
		return daemon
	def stop(self, daemon):
		daemon.close()

class mirrorservice(service):
	def start(self, addr, iface=None):
		daemon = dionaea.mirror.mirrord('tcp', addr, 42, iface)
		return daemon
	def stop(self, daemon):
		daemon.close()

class smbservice(service):
	def start(self, addr,  iface=None):
		daemon = smb.smbd()
		daemon.bind(addr, 445, iface=iface)
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()

class epmapservice(service):
	def start(self, addr,  iface=None):
		daemon = smb.epmapper()
		daemon.bind(addr, 135, iface=iface)
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()

class siptcpservice(service):
	def start(self, addr, iface=None):
		port = int(g_dionaea.config()['modules']['python']['sip']['tcp'].get('port', 5060))
		daemon = dionaea.sip.SipSession(proto = 'tcp')
		daemon.bind(addr, port, iface=iface)
		daemon.listen()
		return daemon

	def stop(self, daemon):
		daemon.close()

class siptlsservice(service):
	def start(self, addr, iface=None):
		port = int(g_dionaea.config()['modules']['python']['sip']['tls'].get('port', 5061))
		daemon = dionaea.sip.SipSession(proto = 'tls')
		daemon.bind(addr, port, iface=iface)
		daemon.listen()
		return daemon

	def stop(self, daemon):
		daemon.close()

class sipudpservice(service):
	def start(self, addr, iface=None):
		port = int(g_dionaea.config()['modules']['python']['sip']['udp'].get('port', 5060))
		daemon = dionaea.sip.SipSession(proto = 'udp')
		daemon.bind(addr, port, iface=iface)
		daemon.listen()
		return daemon

	def stop(self, daemon):
		daemon.close()

class mssqlservice(service):
	def start(self, addr,  iface=None):
		daemon = mssql.mssqld()
		daemon.bind(addr, 1433, iface=iface)
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()

class mysqlservice(service):
	def start(self, addr,  iface=None):
		daemon = mysql.mysqld()
		daemon.bind(addr, 3306, iface=iface)
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()

class pptpservice(service):
	def start(self, addr,  iface=None):
		daemon = pptp.pptpd()
		daemon.bind(addr, 1723, iface=iface)
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()

class mqttservice(service):
	def start(self, addr,  iface=None):
		daemon = mqtt.mqttd()
		daemon.bind(addr, 1883, iface=iface)
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()

class upnpservice(service):
	def start(self, addr,  iface=None):
		daemon = upnp.upnpd()
		daemon.bind(addr, 1900, iface=iface)
		daemon.chroot(g_dionaea.config()['modules']['python']['upnp']['root'])
		daemon.listen()
		return daemon
	def stop(self, daemon):
		daemon.close()

#mode = 'getifaddrs'
#mode = 'manual'
#addrs = { 'eth0' : ['127.0.0.1', '192.168.47.11'] }
mode = g_dionaea.config()['listen']['mode']
addrs = {} 
ifaces = None
#def start():
#	global g_slave, mode, addrs
#	global addrs
#	g_slave.start(addrs)

def new():
	print("START")
	global g_slave, mode, addrs
	global addrs
	if mode == 'manual':
		addrs = g_dionaea.config()['listen']['addrs']
		g_slave = slave()
	elif mode == 'getifaddrs':
		g_slave = slave()
		ifaces = g_dionaea.getifaddrs()
		addrs = {}
		for iface in ifaces.keys():
			afs = ifaces[iface]
			for af in afs.keys():
				if af == 2 or af == 10:
					configs = afs[af]
					for config in afs[af]:
						if iface not in addrs:
							addrs[iface] = []
						addrs[iface].append(config['addr'])
		print(addrs)
	elif mode == 'nl':
		g_slave = nlslave()
		g_slave.ifaces = g_dionaea.config()['listen']['interfaces']



	if "http" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(httpservice)

	if "https" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(httpsservice)

	if "tftp" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(tftpservice)

	if "ftp" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(ftpservice)

	if "mirror" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(mirrorservice)

	if "smb" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(smbservice)

	if "epmap" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(epmapservice)

	if "sip" in g_dionaea.config()['modules']['python']['services']['serve']:
		for proto,factory in {'tcp': siptcpservice, 'tls': siptlsservice, 'udp': sipudpservice}.items():
			if proto in g_dionaea.config()['modules']['python']['sip']:
				g_slave.services.append(factory)

	if "mssql" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(mssqlservice)
		
	if "mysql" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(mysqlservice)

	if "pptp" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(pptpservice)

	if "mqtt" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(mqttservice)

	if "upnp" in g_dionaea.config()['modules']['python']['services']['serve']:
		g_slave.services.append(upnpservice)

	g_slave.start(addrs)



def stop():
	print("STOP")	
	global g_slave
	for addr in g_slave.daemons:
		for s in g_slave.daemons[addr]:
			for d in g_slave.daemons[addr][s]:
				s.stop(s, d)
	del g_slave
