//
//  MeasuringPackerTests.swift
//  PackTests
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation
import Testing

@testable import Pack

private func writeDocument<P: Packer>(to packer: inout P) throws {
	try packer.pack("MESH", using: .ascii, framing: .fixed(byteCount: 4))
	try packer.withLengthPrefix(.uint64) { packer in
		try packer.pack(Double.pi)
		try packer.pack(contentsOf: [Float(1), 2, 3], countPrefixedBy: .uint32)
		try packer.pack("a name", framing: .lengthPrefixed(.uint16))
	}
	try packer.pack(Color(name: "Measured", red: 1, green: 0, blue: 0))
}

@Suite("Measuring")
struct MeasuringPackerTests {
	@Test("A measured size matches the bytes actually packed")
	func measuresAccurately() throws {
		var measure = MeasuringPacker(configuration: .littleEndian)
		try writeDocument(to: &measure)

		let data = try packedToData(.littleEndian, writeDocument)

		#expect(measure.packedCount == data.count)
	}

	@Test("A measuring packer produces no bytes but still validates")
	func validatesWhileMeasuring() throws {
		var measure = MeasuringPacker(configuration: .bigEndian)

		expectPackError(.valueOutOfRange) {
			try measure.pack("TOOLONG", using: .ascii, framing: .fixed(byteCount: 4))
		}
	}

	@Test("Placeholder misuse is caught while measuring")
	func placeholderMisuse() throws {
		var measure = MeasuringPacker(configuration: .bigEndian)
		var other = MeasuringPacker(configuration: .bigEndian)

		let placeholder = try measure.reserve(UInt32.self)
		try measure.fill(placeholder, with: UInt32(0))

		expectPackError(.placeholderAlreadyFilled) {
			try measure.fill(placeholder, with: UInt32(0))
		}

		let foreign = try other.reserve(UInt32.self)

		expectPackError(.invalidPlaceholder) {
			try measure.fill(foreign, with: UInt32(0))
		}
	}

	@Test("Measuring can size a destination before packing into it")
	func reserveCapacity() throws {
		var measure = MeasuringPacker(configuration: .littleEndian)
		try measure.pack(contentsOf: [Double](repeating: .pi, count: 1000))

		#expect(measure.packedCount == 8000)

		var destination = DataDestination()
		destination.reserveCapacity(measure.packedCount)

		var packer = BinaryPacker(destination: destination, configuration: .littleEndian)
		try packer.pack(contentsOf: [Double](repeating: .pi, count: 1000))

		#expect(packer.destination.data.count == 8000)
	}
}
