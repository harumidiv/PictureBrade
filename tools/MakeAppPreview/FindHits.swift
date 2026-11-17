// 画面収録の音から、急に大きな音が鳴った秒数（ブレードが当たった瞬間の候補）を出す。
// 使い方: swift tools/MakeAppPreview/FindHits.swift <画面収録.mp4>
import AVFoundation
let a=AVURLAsset(url:URL(fileURLWithPath:CommandLine.arguments[1]))
let sem=DispatchSemaphore(value:0)
Task {
let t=try await a.loadTracks(withMediaType:.audio)[0]
let r=try AVAssetReader(asset:a)
let o=AVAssetReaderTrackOutput(track:t,outputSettings:[AVFormatIDKey:kAudioFormatLinearPCM,AVLinearPCMBitDepthKey:16,AVLinearPCMIsFloatKey:false,AVLinearPCMIsNonInterleaved:false,AVNumberOfChannelsKey:1,AVSampleRateKey:8000])
r.add(o); r.startReading()
var s=[Int16]()
while let b=o.copyNextSampleBuffer(), let bb=CMSampleBufferGetDataBuffer(b) { var len=0; var p:UnsafeMutablePointer<CChar>?; CMBlockBufferGetDataPointer(bb,atOffset:0,lengthAtOffsetOut:nil,totalLengthOut:&len,dataPointerOut:&p); p!.withMemoryRebound(to:Int16.self,capacity:len/2){ s.append(contentsOf:UnsafeBufferPointer(start:$0,count:len/2)) } }
let win=400 // 50ms
var env=[Double]()
var i=0; while i+win<=s.count { var m=0.0; for j in i..<i+win { m+=Double(s[j])*Double(s[j]) }; env.append(sqrt(m/Double(win))); i+=win }
// onset: env jumps > 2.5x of prev 300ms avg and above threshold
let sorted=env.sorted(); let thr=sorted[Int(Double(sorted.count)*0.9)]
var last = -10.0
for k in 6..<env.count { let prev=env[(k-6)..<k].reduce(0,+)/6; let tt=Double(k)*0.05
 if env[k]>thr && env[k]>prev*2.2 && tt-last>0.4 { print(String(format:"%.2f  %.0f  x%.1f",tt,env[k],env[k]/max(prev,1))); last=tt } }
sem.signal() }
sem.wait()
