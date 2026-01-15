package com.example.sentifire

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.Executors
import org.json.JSONObject
import org.json.JSONArray

class NetworkScanner(private val context: Context) {
    
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    private val executor = Executors.newFixedThreadPool(20)
    
    
    fun getNetworkInfo(): NetworkInfo {
        try {
            val wifiInfo = wifiManager.connectionInfo
            val dhcpInfo = wifiManager.dhcpInfo
            
            var ssid = wifiInfo.ssid?.replace("\"", "") ?: ""
            
            // Try multiple methods to get SSID
            if (ssid.isEmpty() || ssid == "<unknown ssid>" || ssid == "0x") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    // Method 1: Try NetworkCapabilities
                    val network = connectivityManager.activeNetwork
                    val capabilities = connectivityManager.getNetworkCapabilities(network)
                    if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) {
                        val wifiInfo2 = capabilities.transportInfo as? android.net.wifi.WifiInfo
                        val ssidFromCap = wifiInfo2?.ssid?.replace("\"", "")
                        if (!ssidFromCap.isNullOrEmpty() && ssidFromCap != "<unknown ssid>") {
                            ssid = ssidFromCap
                        } else {
                            // Method 2: Check if location is enabled
                            val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as android.location.LocationManager
                            val isLocationEnabled = locationManager.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) ||
                                                   locationManager.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER)
                            
                            if (!isLocationEnabled) {
                                ssid = "Enable GPS to see network name"
                            } else {
                                // Method 3: Try to use BSSID as identifier
                                val bssid = wifiInfo2?.bssid ?: wifiInfo.bssid
                                if (bssid != null && bssid != "02:00:00:00:00:00") {
                                    ssid = "WiFi-${bssid.takeLast(8).replace(":", "")}"
                                } else {
                                    ssid = "Wi-Fi Network"
                                }
                            }
                        }
                    } else {
                        ssid = "Not connected to WiFi"
                    }
                } else {
                    // Pre-Android 10
                    ssid = "Wi-Fi Network"
                }
            }
            
            // Final cleanup
            if (ssid == "<unknown ssid>") ssid = "Enable GPS for network name"
            
            val ipAddress = wifiManager.connectionInfo.ipAddress
            val ownIp = intToIp(ipAddress)
            val gatewayIp = intToIp(dhcpInfo.gateway)
            val netmask = dhcpInfo.netmask
            val subnetMask = intToIp(netmask)
            
            val dnsServers = mutableListOf<String>()
            val dns1 = intToIp(dhcpInfo.dns1)
            val dns2 = intToIp(dhcpInfo.dns2)
            if (dns1 != "0.0.0.0") dnsServers.add(dns1)
            if (dns2 != "0.0.0.0") dnsServers.add(dns2)
            
            val network = connectivityManager.activeNetwork
            val capabilities = connectivityManager.getNetworkCapabilities(network)
            val connectionType = when {
                capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> "WiFi"
                capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> "Cellular"
                capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true -> "Ethernet"
                else -> "Unknown"
            }
            
            val isConnected = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
            
            return NetworkInfo(
                ssid = ssid,
                ownIp = ownIp,
                gatewayIp = gatewayIp,
                subnetMask = subnetMask,
                dnsServers = dnsServers,
                connectionType = connectionType,
                isConnected = isConnected
            )
        } catch (e: Exception) {
            return NetworkInfo("Unknown Network", "0.0.0.0", "0.0.0.0", "0.0.0.0", emptyList(), "None", false)
        }
    }

    fun isConnected(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }
    
    fun scanSubnet(callback: (List<JSONObject>) -> Unit) {
        val dhcpInfo = wifiManager.dhcpInfo
        val gateway = dhcpInfo.gateway
        val ownIpInt = wifiManager.connectionInfo.ipAddress
        val ownIp = intToIp(ownIpInt)
        val gatewayIp = intToIp(gateway)
        val subnetBase = intToIp(gateway).substringBeforeLast(".") 
        
        executor.execute {
            val validDevices = java.util.Collections.synchronizedList(mutableListOf<JSONObject>())
            val threads = mutableListOf<Thread>()
            
            // 1. Get VPN stats if available
            val vpnDevices: Map<String, DiscoveredDevice> = FirewallVpnService.instance?.getDiscoveredDevicesMap() ?: emptyMap()

            for (i in 1..254) {
                val ip = "$subnetBase.$i"
                val t = Thread {
                    try {
                        val inet = InetAddress.getByName(ip)
                        if (inet.isReachable(300) || vpnDevices.containsKey(ip)) {
                            val json = JSONObject()
                            json.put("ip", ip)
                            
                            var hostname = inet.canonicalHostName
                            if (hostname == ip) {
                                hostname = resolveSpecialName(ip, gatewayIp, ownIp)
                            }
                            
                            json.put("hostname", hostname)
                            json.put("is_gateway", ip == gatewayIp)
                            json.put("is_own", ip == ownIp)
                            
                            val vpnDevice = vpnDevices[ip]
                            val ports = vpnDevice?.ports?.toList() ?: emptyList<Int>()
                            if (ports.isNotEmpty()) {
                                 json.put("open_ports", JSONArray(ports))
                            }

                            validDevices.add(json)
                        }
                    } catch (e: Exception) { }
                }
                threads.add(t)
                t.start()
            }
            
            threads.forEach { it.join() }
            callback(validDevices.toList())
        }
    }
    
    fun scanPorts(ip: String, callback: (List<Int>) -> Unit) {
        val commonPorts = listOf(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 3306, 3389, 5900, 8080)
        executor.execute {
            val openPorts = java.util.Collections.synchronizedList(mutableListOf<Int>())
            val threads = mutableListOf<Thread>()
            
            for (port in commonPorts) {
                val t = Thread {
                    try {
                        val socket = Socket()
                        socket.connect(InetSocketAddress(ip, port), 200)
                        socket.close()
                        openPorts.add(port)
                    } catch (e: Exception) { }
                }
                threads.add(t)
                t.start()
            }
            threads.forEach { it.join() }
            callback(openPorts.sorted())
        }
    }

    private fun resolveSpecialName(ip: String, gatewayIp: String, ownIp: String): String {
        return when (ip) {
            "8.8.8.8" -> "Google DNS (Primary)"
            "8.8.4.4" -> "Google DNS (Secondary)"
            "1.1.1.1" -> "Cloudflare DNS"
            gatewayIp -> "Gateway / Router"
            ownIp -> "My Device"
            else -> "Unknown Device"
        }
    }
    
    private fun intToIp(ip: Int): String {
        return "${ip and 0xFF}.${ip shr 8 and 0xFF}.${ip shr 16 and 0xFF}.${ip shr 24 and 0xFF}"
    }
}
