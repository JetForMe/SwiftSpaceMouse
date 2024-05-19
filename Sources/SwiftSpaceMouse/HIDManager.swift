//
//  HIDManager.swift
//  SwiftSpaceMouse
//
//  Created by Rick Mann on 2021-01-05.
//

import Foundation
import IOKit
//import IOKit.hid


protocol
HIDManagerDelegate : AnyObject
{
	func deviceValueReceived(device inDevice: HIDDevice, usagePage inPage: UInt32, usage inUsage: UInt32, value inValue: IOHIDValue)
}

/**
	This is a very simplistic HIDManager wrapper that hard-codes device lookups,
	and makes a lot of assumptions (like there's only one particular device attached).
	
	Note: The USB entitlement must be enabled. If you get "IOServiceOpen failed: 0xe00002e2", try enabling that.
	
	What is "Error opening HIDDevice: 0xe00002c5, 709"?
	
*/

class
HIDManager
{
	static var shared = HIDManager()
	
	private
	init()
	{
		IOHIDManagerRegisterDeviceMatchingCallback(self.hm, self.attachCallback, Unmanaged<HIDManager>.passUnretained(self).toOpaque())
		IOHIDManagerRegisterDeviceRemovalCallback(self.hm, self.detachCallback, Unmanaged<HIDManager>.passUnretained(self).toOpaque())
		
		let criteria = [
			kIOHIDDeviceUsagePageKey: 0x01,		//	Generic Desktop
			kIOHIDDeviceUsageKey: 0x08			//	Multi-axis Controller
		] as CFDictionary
		IOHIDManagerSetDeviceMatching(self.hm, criteria)
		
		IOHIDManagerScheduleWithRunLoop(self.hm, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
		IOHIDManagerOpen(self.hm, IOOptionBits(kIOHIDOptionsTypeNone))
	}
	
	deinit
	{
		IOHIDManagerClose(self.hm, IOOptionBits(kIOHIDOptionsTypeNone))
	}
	
	func
	attached(result: IOReturn, device inDevice: IOHIDDevice)
	{
		debugLog("attached: \(inDevice)")
		let device = HIDDevice(systemDevice: inDevice, delegate: self)
		self.devices.append(device)
	}
	
	func
	detached(result: IOReturn, device inDevice: IOHIDDevice)
	{
		debugLog("detached: \(inDevice)")
		self.devices.removeAll { $0.device == inDevice }
	}
	
	let			hm												=	IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
	var			devices											=	[HIDDevice]()
	weak var	delegate			:	HIDManagerDelegate?
	
	var			attachCallback		:	IOHIDDeviceCallback		=	{ (inCTX, inResult, inSender, inDevice) in
																		let this = Unmanaged<HIDManager>.fromOpaque(inCTX!).takeUnretainedValue()
																		this.attached(result: inResult, device: inDevice)
																	}
	var			detachCallback		:	IOHIDDeviceCallback		=	{ (inCTX, inResult, inSender, inDevice) in
																		let this = Unmanaged<HIDManager>.fromOpaque(inCTX!).takeUnretainedValue()
																		this.detached(result: inResult, device: inDevice)
																	}
}

extension
HIDManager
{
	public
	enum UsagePage : UInt32
	{
		case undefined			=	0x00
		case genericDesktop		=	0x01
		case led				=	0x08
		case button				=	0x09
	}
	
	public
	enum GenericDesktopUsage : UInt32
	{
		case undefined			=	0x00
		case x					=	0x30
		case y					=	0x31
		case z					=	0x32
		case rX					=	0x33
		case rY					=	0x34
		case rZ					=	0x35
	}
}

/**
	TODO: For now we're routing all device callbacks thruogh the HIDManager. This probably isn't right.
*/

extension
HIDManager : HIDDeviceDelegate
{
	func
	valueReceived(device inDevice: HIDDevice, usagePage inPage: UInt32, usage inUsage: UInt32, value inValue: IOHIDValue)
	{
		self.delegate?.deviceValueReceived(device: inDevice, usagePage: inPage, usage: inUsage, value: inValue)
	}
	
}

class
HIDDevice
{
	init(systemDevice inDevice: IOHIDDevice, delegate inDelegate: HIDDeviceDelegate? = nil)
	{
		self.device = inDevice
		self.delegate = inDelegate
		
		let result = IOHIDDeviceOpen(self.device, IOOptionBits(kIOHIDOptionsTypeNone))
		if result != kIOReturnSuccess
		{
			debugLog("Error opening HIDDevice: \(String(format: "0x%08x, %d", result, result & 0x3fff))")
		}
		
		IOHIDDeviceRegisterInputValueCallback(self.device, valueCallback, Unmanaged<HIDDevice>.passUnretained(self).toOpaque())
		if let ps = IOHIDDeviceGetProperty(self.device, "Product" as CFString) as? String
		{
			debugLog("Product: \(ps)")
		}
	}
	
	deinit
	{
		IOHIDDeviceClose(self.device, IOOptionBits(kIOHIDOptionsTypeNone))
	}
	
	func
	valueReceived(result inResult: IOReturn, value inValue: IOHIDValue)
	{
		let element = inValue.element
		let usagePage = element.usagePage
		let usage = element.usage
		self.delegate?.valueReceived(device: self, usagePage: usagePage, usage: usage, value: inValue)
	}
	
	let		elementTypes: [IOHIDElementType : String] =
								[
									//	Many more exist
									kIOHIDElementTypeInput_Button : "Button",
									kIOHIDElementTypeInput_Axis : "Axis",
									kIOHIDElementTypeCollection : "Collection",
								]
	func
	getString(forProperty inKey: String)
		-> String?
	{
		return IOHIDDeviceGetProperty(self.device, inKey as CFString) as? String
	}
	
	func
	getInt(forProperty inKey: String)
		-> Int?
	{
		return IOHIDDeviceGetProperty(self.device, inKey as CFString) as? Int
	}
	
	var			device			:	IOHIDDevice
	weak var	delegate		:	HIDDeviceDelegate?
	
	var			valueCallback	:	IOHIDValueCallback		=	{ (inCTX, inResult, inSender, inValue) in
																	let this = Unmanaged<HIDDevice>.fromOpaque(inCTX!).takeUnretainedValue()
																	this.valueReceived(result: inResult, value: inValue)
																}
	lazy var			manufacturer	:	String?			=	self.getString(forProperty: kIOHIDManufacturerKey)
	lazy var			product			:	String?			=	self.getString(forProperty: kIOHIDProductKey)
}

protocol
HIDDeviceDelegate : AnyObject
{
	func		valueReceived(device inDevice: HIDDevice, usagePage inPage: UInt32, usage inUsage: UInt32, value inValue: IOHIDValue)
}

extension
IOHIDElementType : Hashable
{
}

extension
IOHIDValue
{
	var		element						:	IOHIDElement		{ IOHIDValueGetElement(self) }
	var		intValue					:	Int					{ IOHIDValueGetIntegerValue(self) }
	var		scaledValueCalibrated		:	Double				{ IOHIDValueGetScaledValue(self, IOHIDValueScaleType(kIOHIDValueScaleTypeCalibrated)) }
	var		scaledValuePhysical			:	Double				{ IOHIDValueGetScaledValue(self, IOHIDValueScaleType(kIOHIDValueScaleTypePhysical)) }
	var		scaledValueExponent			:	Double				{ IOHIDValueGetScaledValue(self, IOHIDValueScaleType(kIOHIDValueScaleTypeExponent)) }
}

extension
IOHIDElement
{
	var		usagePage					:	UInt32				{ IOHIDElementGetUsagePage(self) }
	var		usage						:	UInt32				{ IOHIDElementGetUsage(self) }
}


func
debugLog<T>(_ inMsg: T, file inFile : String = #file, line inLine : Int = #line)
{
	let file = (inFile as NSString).lastPathComponent
	let s = "\(file):\(inLine)    \(inMsg)"
	print(s)
}

func
debugLog(format inFormat: String, file inFile : String = #file, line inLine : Int = #line, _ inArgs: CVarArg...)
{
	let s = String(format: inFormat, arguments: inArgs)
	debugLog(s, file: inFile, line: inLine)
}
