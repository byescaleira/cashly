import SwiftUI

#if canImport(UIKit)
    import UIKit

    struct MemojiTextInput: UIViewRepresentable {
        @Binding var isActive: Bool
        let onInsert: (NSAttributedString) -> Void

        func makeUIView(context: Context) -> MemojiTextView {
            let view = MemojiTextView()
            view.supportsAdaptiveImageGlyph = true
            view.delegate = context.coordinator
            view.backgroundColor = .clear
            view.tintColor = .clear
            view.font = .preferredFont(forTextStyle: .body)
            view.adjustsFontForContentSizeCategory = true
            view.isScrollEnabled = false
            view.textContainerInset = .zero
            view.textContainer.lineFragmentPadding = 0
            view.autocorrectionType = .no
            view.spellCheckingType = .no
            view.returnKeyType = .done
            return view
        }

        func updateUIView(_ view: MemojiTextView, context: Context) {
            context.coordinator.parent = self
            guard isActive != view.isFirstResponder else { return }
            Task { @MainActor in
                if isActive { view.becomeFirstResponder() } else { view.resignFirstResponder() }
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        @MainActor final class Coordinator: NSObject, UITextViewDelegate {
            var parent: MemojiTextInput

            init(parent: MemojiTextInput) {
                self.parent = parent
            }

            func textViewDidChange(_ textView: UITextView) {
                guard let text = textView.attributedText, text.length > 0 else { return }
                textView.attributedText = NSAttributedString()
                parent.onInsert(text)
            }

            func textView(
                _ textView: UITextView, shouldChangeTextIn range: NSRange,
                replacementText text: String
            ) -> Bool {
                guard text == "\n" else { return true }
                textView.resignFirstResponder()
                return false
            }

            func textViewDidBeginEditing(_ textView: UITextView) {
                if !parent.isActive { parent.isActive = true }
            }

            func textViewDidEndEditing(_ textView: UITextView) {
                if parent.isActive { parent.isActive = false }
            }
        }
    }

    final class MemojiTextView: UITextView {
        override var textInputMode: UITextInputMode? {
            UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
                ?? super.textInputMode
        }
    }
#elseif canImport(AppKit)
    import AppKit

    struct MemojiTextInput: NSViewRepresentable {
        @Binding var isActive: Bool
        let onInsert: (NSAttributedString) -> Void

        func makeNSView(context: Context) -> MemojiTextView {
            let view = MemojiTextView()
            view.isRichText = true
            view.importsGraphics = true
            view.allowsUndo = false
            view.drawsBackground = false
            view.insertionPointColor = .clear
            view.font = .preferredFont(forTextStyle: .body)
            view.textContainerInset = .zero
            view.textContainer?.lineFragmentPadding = 0
            view.delegate = context.coordinator
            return view
        }

        func updateNSView(_ view: MemojiTextView, context: Context) {
            context.coordinator.parent = self
            guard isActive, let window = view.window, window.firstResponder !== view else { return }
            Task { @MainActor in
                window.makeFirstResponder(view)
                NSApp.orderFrontCharacterPalette(view)
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
            var parent: MemojiTextInput

            init(parent: MemojiTextInput) {
                self.parent = parent
            }

            func textDidChange(_ notification: Notification) {
                guard let view = notification.object as? NSTextView,
                    let storage = view.textStorage, storage.length > 0
                else { return }
                let text = NSAttributedString(attributedString: storage)
                storage.setAttributedString(NSAttributedString())
                parent.onInsert(text)
            }

            func textDidBeginEditing(_ notification: Notification) {
                if !parent.isActive { parent.isActive = true }
            }

            func textDidEndEditing(_ notification: Notification) {
                if parent.isActive { parent.isActive = false }
            }
        }
    }

    final class MemojiTextView: NSTextView {
        override var supportsAdaptiveImageGlyph: Bool { true }

        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            NSApp.orderFrontCharacterPalette(self)
        }
    }
#endif
