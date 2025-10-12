//
//  ControlBarView.swift
//  InfiniteVideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//

import SwiftUI
struct ControlBarView: View {
    @State var messageText: String = ""
    @FocusState.Binding var isFocused: Bool
    @State private var textEditorSize = CGSizeZero
    @State private var isTextEmpty = true
    @Binding var isTyping: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            AdaptiveTextEditor(text: $messageText, isFocused: $isFocused, placeholder: "Send message")

            if !isTyping {
                Button {
                    
                } label: {
                    Image(systemName: "heart")
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "paperplane")
                }
            } else if !isTextEmpty {
                Button {
                    
                } label: {
                    Image(systemName: "paperplane")
                }
            }


        }
        .onChange(of: isFocused, perform: { newValue in
            withAnimation {
                isTyping = newValue
            }
        })
        .onChange(of: messageText, perform: { newValue in
            withAnimation {
                isTextEmpty = messageText.isEmpty
            }
        })
        .foregroundStyle(.white)
        .font(.title2)
    }
}

struct AdaptiveTextEditor: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let placeholder: String
    @State private var textHeight: CGFloat?
    @State private var singleLineHeight: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(text.isEmpty ? placeholder : text)
                .lineLimit(5)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .opacity(0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                if text.isEmpty {
                                    self.singleLineHeight = geo.size.height * 0.7
                                }
                                self.textHeight = geo.size.height
                            }.onChange(of: text) { _ in
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    self.textHeight = geo.size.height
                                }
                            }
                    }
                )
            
            TextEditor(text: $text)
                .font(.body)
                .focused($isFocused)
                .frame(height: min(textHeight ?? singleLineHeight, singleLineHeight * 5))
                .padding(.leading, 10)
                .background(.clear)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.white)
                )
                .overlay(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }
        }
    }
}
