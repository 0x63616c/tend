import SwiftUI

struct NotificationPreview: View {
    var time: Date
    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 0) {
                Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day()).font(.system(size: 12, weight: .medium))
                Text(time, format: .dateTime.hour().minute()).font(.system(size: 56, weight: .thin, design: .rounded))
            }.foregroundStyle(.white.opacity(0.9)).padding(.top, 16)
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "waveform.path.ecg").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white).frame(width: 38, height: 38).background(LinearGradient(colors: [Color(red: 0.49, green: 0.43, blue: 0.94), Color(red: 0.30, green: 0.24, blue: 0.70)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 2) {
                    HStack { Text("Time for your check-in").font(.system(size: 13, weight: .semibold)); Spacer(minLength: 4); Text("now").font(.system(size: 11)).foregroundStyle(.secondary) }
                    Text("Open Tend to review your schedule and log your dose.").font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
                }
            }.padding(12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15), lineWidth: 0.5))
            Spacer(minLength: 0)
        }.padding(14).frame(height: 238)
            .background {
                ZStack {
                    Color(red: 0.07, green: 0.08, blue: 0.2)
                    Circle().fill(.indigo).frame(width: 220).blur(radius: 35).offset(x: -100, y: 65)
                    Circle().fill(.cyan.opacity(0.55)).frame(width: 170).blur(radius: 35).offset(x: 100, y: -60)
                }
            }.clipShape(RoundedRectangle(cornerRadius: 26))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Notification preview. Time for your check-in. Open Tend to review your schedule and log your dose.")
    }
}
