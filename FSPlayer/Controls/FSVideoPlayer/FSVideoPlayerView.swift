//
//  FSVideoPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//

//
//  FSVideoPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//

import SwiftUI
import AVKit

struct FSVideoPlayerView: View {
    @StateObject private var viewModel: FSVideoPlayerViewModel

    var onClose: (() -> Void)?
    var buttonColor: Color

    @State private var isAspectFill = false
    @State private var scrubStartValue: Double = 0
    @State private var scrubOffset: CGFloat = 0
    @State private var isScrubbing = false
    @State private var scrubRate: ScrubRate = .normal
    
    enum ScrubRate: String, CaseIterable {
        case slow = "0.5x"
        case normal = "1x"
        case fast = "2x"
        case veryFast = "3x"
        
        var multiplier: Double {
            switch self {
            case .slow: return 0.5
            case .normal: return 1.0
            case .fast: return 2.0
            case .veryFast: return 3.0
            }
        }
        
        var color: Color {
            switch self {
            case .slow: return .blue
            case .normal: return .white
            case .fast: return .orange
            case .veryFast: return .red
            }
        }
    }

    init(player: AVPlayer, buttonColor: Color = .white, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: FSVideoPlayerViewModel(player: player))
        self.onClose = onClose
        self.buttonColor = buttonColor
    }

    var body: some View {
        ZStack {
            FSVideoPlayerLayerView(player: viewModel.player)
                .ignoresSafeArea()
                .onChange(of: isAspectFill) { _, newValue  in
                    viewModel.setAspectFill(newValue)
                }

            VStack {
                topBar
                Spacer()
                
                if isScrubbing {
                    scrubbingIndicator
                }
                
                if viewModel.showControls {
                    controls
                        .transition(.opacity)
                        .padding()
                }
            }
        }
        .onTapGesture {
            viewModel.toggleControls()
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if !isScrubbing {
                        // Начало скраббинга
                        isScrubbing = true
                        scrubStartValue = viewModel.currentTime
                        viewModel.startInteraction()
                        viewModel.pause()
                    }
                    
                    // Обрабатываем смещение пальца по горизонтали для скраббинга
                    scrubOffset = value.translation.width
                    
                    // Определяем скорость скраббинга в зависимости от расстояния смещения
                    let absOffset = abs(scrubOffset)
                    if absOffset < 50 {
                        scrubRate = .slow
                    } else if absOffset < 100 {
                        scrubRate = .normal
                    } else if absOffset < 200 {
                        scrubRate = .fast
                    } else {
                        scrubRate = .veryFast
                    }
                    
                    // Вычисляем новое время
                    let screenWidth = UIScreen.main.bounds.width
                    let scrubAmount = (scrubOffset / screenWidth) * viewModel.duration * scrubRate.multiplier
                    let newTime = scrubStartValue + scrubAmount
                    
                    // Ограничиваем значение в диапазоне продолжительности видео
                    let clampedTime = max(0, min(newTime, viewModel.duration))
                    
                    // Обновляем значение слайдера и предварительный просмотр
                    viewModel.sliderValue = clampedTime
                    viewModel.seekDebounced(to: clampedTime)
                }
                .onEnded { _ in
                    // Окончание скраббинга
                    let finalTime = viewModel.sliderValue
                    viewModel.seekImmediately(to: finalTime)
                    viewModel.endInteraction()
                    viewModel.play()
                    isScrubbing = false
                    scrubOffset = 0
                }
        )
        .onAppear {
            viewModel.startPlaying()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: {
                onClose?()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(buttonColor)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }

            Spacer()

            Button(action: {
                isAspectFill.toggle()
            }) {
                Image(systemName: isAspectFill ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                    .font(.title2)
                    .foregroundColor(buttonColor)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    // MARK: - Scrubbing Indicator
    
    private var scrubbingIndicator: some View {
        VStack {
            HStack {
                // Направление перемотки
                Image(systemName: scrubOffset < 0 ? "backward.fill" : "forward.fill")
                    .foregroundColor(scrubRate.color)
                
                // Скорость перемотки
                Text(scrubRate.rawValue)
                    .fontWeight(.bold)
                    .foregroundColor(scrubRate.color)
                
                // Текущее время
                Text(viewModel.formattedTime(viewModel.sliderValue))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack {
            Spacer()

            HStack(spacing: 40) {
                Button(action: {
                    viewModel.skipBackward()
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 40))
                        .foregroundColor(buttonColor)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }

                Button(action: {
                    viewModel.togglePlayPause()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 50))
                        .foregroundColor(buttonColor)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }

                Button(action: {
                    viewModel.skipForward()
                }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 40))
                        .foregroundColor(buttonColor)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
            .padding()

            Spacer()

            VStack {
                Slider(
                    value: $viewModel.sliderValue,
                    in: 0...viewModel.duration,
                    onEditingChanged: { editing in
                        if editing {
                            viewModel.startInteraction()
                            viewModel.pause()
                        } else {
                            viewModel.seekImmediately(to: viewModel.sliderValue)
                            viewModel.endInteraction()
                            viewModel.play()
                        }
                    }
                )
                .accentColor(.red)
                .onChange(of: viewModel.sliderValue) { _, newValue in
                    if viewModel.isInteracting {
                        viewModel.seekDebounced(to: newValue)
                    }
                }
                
                HStack {
                    Text(viewModel.formattedTime(viewModel.currentTime))
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    Text(viewModel.formattedTime(viewModel.duration))
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
        }
    }
}
