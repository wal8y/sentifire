package com.example.sentifire

import org.json.JSONArray
import org.json.JSONObject
import java.net.InetAddress
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentHashMap

data class DiscoveredDevice(
    val ip: String,
    var hostname: String? = null,
    val ports: MutableSet<Int> = mutableSetOf(),
    var bytesReceived: Long = 0,
    var bytesSent: Long = 0,
    val firstSeen: Long = System.currentTimeMillis(),
    var lastSeen: Long = System.currentTimeMillis(),
    var isBlocked: Boolean = false
)

class PacketAnalyzer {
    
    private val discoveredDevices = ConcurrentHashMap<String, DiscoveredDevice>()
    private val blockedIps = mutableSetOf<String>()
    
    fun analyzePacket(packet: ByteArray, isOutgoing: Boolean): String? {
        if (packet.size < 20) return null
        
        try {
            val buffer = ByteBuffer.wrap(packet)
            
            val versionAndHeaderLength = buffer.get().toInt() and 0xFF
            val version = versionAndHeaderLength shr 4
            
            if (version != 4) return null
            
            buffer.position(12)
            
            val sourceIp = readIpAddress(buffer)
            val destIp = readIpAddress(buffer)
            
            val remoteIp = if (isOutgoing) destIp else sourceIp
            val packetSize = packet.size.toLong()
            
            val device = discoveredDevices.getOrPut(remoteIp) {
                DiscoveredDevice(ip = remoteIp).also {
                    Thread {
                        try {
                            val addr = InetAddress.getByName(remoteIp)
                            it.hostname = addr.canonicalHostName
                        } catch (e: Exception) {}
                    }.start()
                }
            }
            
            device.lastSeen = System.currentTimeMillis()
            if (isOutgoing) {
                device.bytesSent += packetSize
            } else {
                device.bytesReceived += packetSize
            }
            
            buffer.position(9)
            val protocol = buffer.get().toInt() and 0xFF
            
            if (protocol == 6 || protocol == 17) {
                buffer.position(20)
                val srcPort = buffer.short.toInt() and 0xFFFF
                val dstPort = buffer.short.toInt() and 0xFFFF
                
                val remotePort = if (isOutgoing) dstPort else srcPort
                device.ports.add(remotePort)
            }
            
            if (blockedIps.contains(remoteIp)) {
                return remoteIp
            }
            
        } catch (e: Exception) {}
        
        return null
    }
    
    private fun readIpAddress(buffer: ByteBuffer): String {
        val b1 = buffer.get().toInt() and 0xFF
        val b2 = buffer.get().toInt() and 0xFF
        val b3 = buffer.get().toInt() and 0xFF
        val b4 = buffer.get().toInt() and 0xFF
        return "$b1.$b2.$b3.$b4"
    }
    
    fun getDiscoveredDevices(): JSONArray {
        val devices = JSONArray()
        
        discoveredDevices.values.forEach { device ->
            val deviceJson = JSONObject().apply {
                put("ip", device.ip)
                put("hostname", device.hostname ?: "Unknown")
                put("ports", JSONArray(device.ports.toList()))
                put("bytesReceived", device.bytesReceived)
                put("bytesSent", device.bytesSent)
                put("firstSeen", device.firstSeen)
                put("lastSeen", device.lastSeen)
                put("isBlocked", device.isBlocked)
            }
            devices.put(deviceJson)
        }
        
        return devices
    }
    
    fun getDiscoveredDevicesMap(): Map<String, DiscoveredDevice> {
        return HashMap(discoveredDevices)
    }
    
    fun blockIp(ip: String) {
        blockedIps.add(ip)
        discoveredDevices[ip]?.isBlocked = true
    }
    
    fun unblockIp(ip: String) {
        blockedIps.remove(ip)
        discoveredDevices[ip]?.isBlocked = false
    }
    
    fun clearDevices() {
        discoveredDevices.clear()
    }
}
