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
                Text("t").font(.system(size: 30, weight: .medium)).foregroundStyle(.white).frame(width: 38, height: 38).background(Color(white: 0.055), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 2) {
                    HStack { Text(Store.reminderTitle).font(.system(size: 13, weight: .semibold)); Spacer(minLength: 4); Text("now").font(.system(size: 11)).foregroundStyle(.secondary) }
                    Text(Store.reminderBody).font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
                }
            }.padding(12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15), lineWidth: 0.5))
            Spacer(minLength: 0)
        }.padding(14).frame(height: 238)
            .background(Color(white: 0.035)).clipShape(RoundedRectangle(cornerRadius: 26))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Notification preview. Time for your check-in. Open Tend to review your schedule and log your dose.")
    }
}
