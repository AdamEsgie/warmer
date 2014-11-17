//
//  StringExtension.swift
//  warmer
//
//  Created by Adam Salvitti-Gucwa on 11/14/14.
//  Copyright (c) 2014 Esgie. All rights reserved.
//

import Foundation

extension String {
  subscript (i: Int) -> String {
    return String(Array(self)[i])
  }
}