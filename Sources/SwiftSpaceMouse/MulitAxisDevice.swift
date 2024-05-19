//
//  MulitAxisDevice.swift
//  SwiftSpaceMouse
//
//  Created by Rick Mann on 2021-04-26.
//  Copyright © 2021 Latency: Zero, LLC. All rights reserved.
//

import Foundation
import IOKit
//import IOKit.hid

/**
	Makes working with USB HID Multiaxis Devices easier (specifically geared toward
	using the 3DConnexion Space Mouse).
	
	Tested with 3Dconnexion Space Mouse.
	Possible alternative: https://p3america.com/spacemouse-module-usb/
	
	TODO: This will probably affect all views that use it; it really should just affect the frontmost.
*/

class
MultiAxisDevice : ObservableObject
{
	static let shared = MultiAxisDevice()
	
	enum
	Mode
	{
		case camera			//	Spacemouse controls camera
		case model			//	Spacemouse controls scene
	}
	
	private
	init()
	{
		self.hidManager = HIDManager.shared
		self.hidManager.delegate = self
	}
	
	let			hidManager			:	HIDManager
	var			state									=	MultiAxisState()
}


extension
MultiAxisDevice : HIDManagerDelegate
{
	func
	deviceValueReceived(device inDevice: HIDDevice, usagePage inPage: UInt32, usage inUsage: UInt32, value inValue: IOHIDValue)
	{
//		debugLog("Value callback. element: [\(inElement)], usage: \(inUsage), value: \(inValue)")
		
		if inPage == HIDManager.UsagePage.genericDesktop.rawValue
		{
			let usage = HIDManager.GenericDesktopUsage(rawValue: inUsage) ?? .undefined
			
			let value = inValue.scaledValueCalibrated
			
			var state = self.state
			
			//	The 3Dconnexion Space Mouse has axes X left-right, Y front-back, and Z up-down.
			
			switch (usage)
			{
				case .rX:		state.pitch = Float(value)
				case .rY:		state.roll = Float(value)
				case .rZ:		state.yaw = Float(value)
				case .x:		state.x = Float(value)
				case .y:		state.z = Float(value)
				case .z:		state.y = Float(value)
				
				default:
					break
			}

			self.state = state

//			debugLog("3D: \(state.pitch, specifier: "%7.1f"), \(state.yaw, specifier: "%7.1f"), \(state.roll, specifier: "%7.1f")")		//	TODO: Really change to float here?
		}
		else if inPage == HIDManager.UsagePage.button.rawValue
		{
		}
	}
	
}

struct
MultiAxisState
{
	var			pitch		:	Float		=	0
	var			yaw			:	Float		=	0
	var			roll		:	Float		=	0
	var			x			:	Float		=	0
	var			y			:	Float		=	0
	var			z			:	Float		=	0
}

/*
3Dconnexion SpaceMouse Compact dump from USB Prober.app:

Device Descriptor
	Descriptor Version Number:   0x0200
	Device Class:   0   (Composite)
	Device Subclass:   0
	Device Protocol:   0
	Device MaxPacketSize:   8
	Device VendorID/ProductID:   0x256F/0xC635   (unknown vendor)
	Device Version Number:   0x0437
	Number of Configurations:   1
	Manufacturer String:   1 "3Dconnexion"
	Product String:   2 "SpaceMouse Compact"
	Serial Number String:   0 (none)

Usage Page    (Generic Desktop)
Usage (8 (0x8))
Collection (Application)
	Collection (Physical)
	  ReportID................    (1)
	  Logical Minimum.........    (65186)
	  Logical Maximum.........    (350)
	  Physical Minimum........    (64136)
	  Physical Maximum........    (1400)
	  Unit Exponent...........    (12)
	  Unit....................    (17)
	  Usage (X)
	  Usage (Y)
	  Usage (Z)
	  Report Size.............    (16)
	  Report Count............    (3)
	  Input...................   (Data, Variable, Relative, No Wrap, Linear, Preferred State, No Null Position, Bitfield)
	End Collection
	Collection (Physical)
	  ReportID................    (2)
	  Usage (Rx)
	  Usage (Ry)
	  Usage (Rz)
	  Report Size.............    (16)
	  Report Count............    (3)
	  Input...................   (Data, Variable, Relative, No Wrap, Linear, Preferred State, No Null Position, Bitfield)
	End Collection
	Collection (Logical)
	  ReportID................    (3)
	  Usage Page    (Generic Desktop)
	  Usage Page    (Button)
	  Usage Minimum...........    (1)
	  Usage Maximum...........    (2)
	  Logical Minimum.........    (0)
	  Logical Maximum.........    (1)
	  Physical Minimum........    (0)
	  Physical Maximum........    (1)
	  Report Size.............    (1)
	  Report Count............    (2)
	  Input...................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Bitfield)
	  Report Count............    (14)
	  Input...................   (Constant, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Bitfield)
	End Collection
	Collection (Logical)
	  ReportID................    (4)
	  Usage Page    (LED)
	  Usage 75 (0x4b)
	  Logical Minimum.........    (0)
	  Logical Maximum.........    (1)
	  Report Count............    (1)
	  Report Size.............    (1)
	  Output..................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
	  Report Count............    (1)
	  Report Size.............    (7)
	  Output..................   (Constant, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
	End Collection
Usage Page    (Vendor defined 0)
Usage 1 (0x1)
	Collection (Logical)
	  Logical Minimum.........    (-128)
	  Logical Maximum.........    (127)
	  Report Size.............    (8)
	  Usage 58 (0x3a)
		  Collection (Logical)
			ReportID................    (5)
			Usage 32 (0x20)
			Report Count............    (1)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (6)
			Usage 33 (0x21)
			Report Count............    (1)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (7)
			Usage 34 (0x22)
			Report Count............    (1)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (8)
			Usage 35 (0x23)
			Report Count............    (7)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (9)
			Usage 36 (0x24)
			Report Count............    (7)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (10)
			Usage 37 (0x25)
			Report Count............    (7)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (11)
			Usage 38 (0x26)
			Report Count............    (1)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (19)
			Usage 46 (0x2e)
			Report Count............    (1)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (25)
			Usage 49 (0x31)
			Report Count............    (4)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
		  Collection (Logical)
			ReportID................    (26)
			Usage 50 (0x32)
			Report Count............    (7)
			Feature.................   (Data, Variable, Absolute, No Wrap, Linear, Preferred State, No Null Position, Nonvolatile, Bitfield)
		  End Collection
	End Collection
End Collection
*/
