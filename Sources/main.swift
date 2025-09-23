//
//  main.swift
//  Chordinate
//
//  Created by Donald Wayne Moore Jr. on 9/23/25.
//
import Foundation

print("Chordinate • type 'help' or 'quit'")

while true {
    // prompt
    FileHandle.standardOutput.write("> ".data(using: .utf8)!)

    guard let line = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
    if line.isEmpty { continue }

    switch line.lowercased() {
    case "help":
        print("""
        Commands:
          help         show this help
          ping         quick health check
          time         print current time
          quit/exit    leave
        """)
    case "ping":
        print("pong")
    case "time":
        print(Date().description)
    case "quit", "exit":
        print("bye")
        exit(EXIT_SUCCESS)
    default:
        print("unknown command: \(line)")
    }
}
