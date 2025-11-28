//
//  AsyncButton.swift
//  Transcriber
//
//  Created by Kavi Gupta on 10/6/25.
//

import SwiftUI

struct AsyncButton: View {
    @State private var touchDown = false
    @State private var isPopupPresented = false
    
    var body: some View {
        
        Text("Complete")
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 150, height: 40, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.secondary)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.red)
                        // I prefer the effect of using an offset instead of width
                            .offset(x: touchDown ? 0 : -150)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0).onChanged({ value in
                    if !touchDown {
                        withAnimation(.linear(duration: 2)) {
                            touchDown = true
                        }
                    }
                }).onEnded({ _ in
                    if !isPopupPresented {
                        touchDown = false
                    }
                })
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 2, maximumDistance: .infinity)
                    .onEnded({ _ in
                        isPopupPresented = true
                    })
            )
            .sheet(isPresented: $isPopupPresented) {
                Text("Foo")
            }
    }
}

#Preview {
    AsyncButton()
}
