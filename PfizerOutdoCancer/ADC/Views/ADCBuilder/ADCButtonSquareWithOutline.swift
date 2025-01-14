import SwiftUI

struct ADCButtonSquareWithOutline: View {
    @Environment(AppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    let imageName: String
    let outlineColor: Color
    let description: String
    let index: Int
    let isSelected: () -> Bool
    let action: () -> Void
    let buttonSize: CGFloat = 110.0
    let cornerRadius: CGFloat = 12.0
    
    
    var body: some View {
        VStack (alignment: .center) {
            Button {
                action()
            } label: {
               Image(imageName)
                   .resizable()
                   .aspectRatio(contentMode: .fit)
                   .frame(width: buttonSize, height: buttonSize)
                   .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                   .overlay {
                       RoundedRectangle(cornerRadius: cornerRadius)
                           .stroke(isSelected() ? Color.white : Color.clear, lineWidth: 4)
                   }
           }
           .frame(width: buttonSize, height: buttonSize)
           .buttonBorderShape(ButtonBorderShape.roundedRectangle(radius: cornerRadius))
            
            Text(description)
                .multilineTextAlignment(.center)
                .font(.system(size: 10))
                .padding(.horizontal,2)
                .padding(.top, 2)
                .frame(maxWidth: buttonSize)
        }
    }
    
}

