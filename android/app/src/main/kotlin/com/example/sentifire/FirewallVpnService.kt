package com.example.sentifire

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import kotlin.concurrent.thread

class FirewallVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = false
    private val packetAnalyzer = PacketAnalyzer()
    
    private val CHANNEL_ID = "FirewallVPN"
    private val NOTIFICATION_ID = 1

    companion object {
        const val ACTION_START = "com.example.sentifire.START_VPN"
        const val ACTION_STOP = "com.example.sentifire.STOP_VPN"
        const val ACTION_BLOCK_IP = "com.example.sentifire.BLOCK_IP"
        const val ACTION_UNBLOCK_IP = "com.example.sentifire.UNBLOCK_IP"
        const val EXTRA_IP = "com.example.sentifire.EXTRA_IP"
        var instance: FirewallVpnService? = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startVpn()
            ACTION_STOP -> stopVpn()
            ACTION_BLOCK_IP -> {
                val ip = intent.getStringExtra(EXTRA_IP)
                if (ip != null) packetAnalyzer.blockIp(ip)
            }
            ACTION_UNBLOCK_IP -> {
                val ip = intent.getStringExtra(EXTRA_IP)
                if (ip != null) packetAnalyzer.unblockIp(ip)
            }
        }
        return START_STICKY
    }

    private fun startVpn() {
        if (isRunning) return

        createNotificationChannel()

        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        val builder = Builder()
            .setSession("Sentinel Firewall")
            .addAddress("10.0.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
            .addDnsServer("8.8.4.4")
            .addDisallowedApplication(packageName)
            
        vpnInterface = builder.establish()

        if (vpnInterface != null) {
            isRunning = true
            thread { processPackets() }
        }
    }

    private fun processPackets() {
        val vpnInput = FileInputStream(vpnInterface?.fileDescriptor)
        val vpnOutput = FileOutputStream(vpnInterface?.fileDescriptor)
        val buffer = ByteBuffer.allocate(32767)

        try {
            while (isRunning) {
                val length = vpnInput.read(buffer.array())
                if (length > 0) {
                    buffer.limit(length)
                    
                    val packet = ByteArray(length)
                    buffer.get(packet)
                    buffer.clear()
                    
                    val blockedIp = packetAnalyzer.analyzePacket(packet, isOutgoing = true)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            try {
                vpnInput.close()
                vpnOutput.close()
            } catch (e: Exception) {}
        }
    }

    private fun stopVpn() {
        isRunning = false
        try {
            vpnInterface?.close()
        } catch (e: Exception) {}
        vpnInterface = null
        stopForeground(true)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Firewall VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Sentinel Network Firewall"
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sentinel Firewall Active")
            .setContentText("Your device is protected")
            .setSmallIcon(android.R.drawable.ic_secure)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    fun getDiscoveredDevices() = packetAnalyzer.getDiscoveredDevices()
    fun getDiscoveredDevicesMap() = packetAnalyzer.getDiscoveredDevicesMap()

    override fun onDestroy() {
        stopVpn()
        instance = null
        super.onDestroy()
    }
}
