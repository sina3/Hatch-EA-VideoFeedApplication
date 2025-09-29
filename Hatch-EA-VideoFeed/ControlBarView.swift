//
//  ControlBarView.swift
//  Hatch-EA-VideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//

import SwiftUI
struct ControlBarView: View {
    @State var messageText: String = ""
    @FocusState var isFocused: Bool
    @State private var textEditorSize = CGSizeZero
    var onFocusChange: (Bool) -> ()
//    @Binding var isTyping: Bool {
//        didSet {
//            isFocused = isTyping
//        }
//    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            TextEditor(text: $messageText)
                .focused($isFocused)
                .background(.clear)
                .frame(height: 50)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.white)
                )

            Button {
                
            } label: {
                Image(systemName: "heart")
            }
            
            Button {
                
            } label: {
                Image(systemName: "paperplane")
            }

        }
        .onChange(of: isFocused, perform: { newValue in
            onFocusChange(newValue)
        })
        .foregroundStyle(.white)
        .font(.title2)
    }
}
