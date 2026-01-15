package com.example.sentifire

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    private val VPN_CHANNEL = "com.example.sentifire/vpn"
    private val NETWORK_CHANNEL = "com.example.sentifire/network"
    private val VPN_REQUEST_CODE = 1
    private val LOCATION_PERMISSION_CODE = 2
    
    private var vpnPermissionResult: MethodChannel.Result? = null
    private lateinit var networkScanner: NetworkScanner

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        networkScanner = NetworkScanner(this)
        checkLocationPermission()
    }

    private fun checkLocationPermission() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), LOCATION_PERMISSION_CODE)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    val intent = VpnService.prepare(applicationContext)
                    if (intent != null) {
                        vpnPermissionResult = result
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        result.success(true)
                    }
                }
                "start" -> {
                    val intent = Intent(this, FirewallVpnService::class.java).apply {
                        action = FirewallVpnService.ACTION_START
                    }
                    startService(intent)
                    result.success(true)
                }
                "stop" -> {
                    val intent = Intent(this, FirewallVpnService::class.java).apply {
                        action = FirewallVpnService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "blockIp" -> {
                    val ip = call.argument<String>("ip")
                    val intent = Intent(this, FirewallVpnService::class.java).apply {
                        action = FirewallVpnService.ACTION_BLOCK_IP
                        putExtra(FirewallVpnService.EXTRA_IP, ip)
                    }
                    startService(intent)
                    result.success(true)
                }
                "unblockIp" -> {
                    val ip = call.argument<String>("ip")
                    val intent = Intent(this, FirewallVpnService::class.java).apply {
                        action = FirewallVpnService.ACTION_UNBLOCK_IP
                        putExtra(FirewallVpnService.EXTRA_IP, ip)
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNetworkInfo" -> {
                    val info = networkScanner.getNetworkInfo()
                    result.success(info.toJson().toString())
                }
                "getDiscoveredDevices" -> {
                    networkScanner.scanSubnet { devices ->
                        val jsonArray = org.json.JSONArray(devices)
                        runOnUiThread {
                            result.success(jsonArray.toString())
                        }
                    }
                }
                "scanPorts" -> {
                    val ip = call.argument<String>("ip")
                    if (ip != null) {
                        networkScanner.scanPorts(ip) { ports ->
                             runOnUiThread {
                                result.success(ports)
                             }
                        }
                    } else {
                        result.error("INVALID_IP", "IP address is null", null)
                    }
                }
                "isConnected" -> {
                    result.success(networkScanner.isConnected())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            vpnPermissionResult?.success(resultCode == Activity.RESULT_OK)
            vpnPermissionResult = null
        }
    }
}
