clear all
fc = 1090e6;
fs = 2.4e6;                      % sample rate in baseband
Ns = 375000;                      % samples per frame
Nfr = 100;                      % number of frames

preamble=[1 -1 1 -1 -1 -1 -1 1 -1 1 -1 -1 -1 -1 -1 -1];

Interpolated_preamble=repmat(preamble,6,1);
    
Interpolated_preamble=reshape(Interpolated_preamble,1,[]);
 s_len=length(Interpolated_preamble);
Tfr = Ns/fs;  disp(['Frame duration: ' num2str(1000*Tfr) ' ms'])
 k=0;
sdr = sdrinfo;
if isempty(sdr), error('No RTL-SDR radio found'), end

rx = comm.SDRRTLReceiver('CenterFrequency',fc, 'SampleRate',fs, 'SamplesPerFrame',Ns, ...
  'OutputDataType','double');
for nfr = 1:Nfr
  [y1, datavalid, overflow] = rx();
  %if overflow, disp(['frame ' int2str(nfr) ': overflow!']), end
  if ~datavalid, warning('data not valid'),
  end
        

    
    %reshape(remat(s,6,1),1,[])
    
    err=1;
    
    interpolator=dsp.FIRInterpolator(5);
    
    y=interpolator(y1);
    
    y1=conj(y);
    
    realSignal=y.*y1;
    clear y1;
   
    corr=zeros(length(Interpolated_preamble)-s_len);
    %matric calculation coorrelation
    for j=1:length(realSignal)-1440
        slidingwindow=realSignal(j:j+s_len-1);
       slidingwindow=slidingwindow- mean(slidingwindow);
        corr(j)=sum(Interpolated_preamble.*slidingwindow');
        dist(j)=sqrt(sum((slidingwindow'-Interpolated_preamble).^2));
        
    end
    [~,peakIndx]=maxk(corr,100);
     j=1;
    
    clear slidingwindow;
    while(err==1&&j<=100)
       
    
        indxD=peakIndx(j);
        sync1=realSignal(indxD:indxD+s_len-1);            
        x=realSignal(indxD+s_len:end);
        pad_size=mod(numel(x),12);
        pad_size=12-pad_size;
        x_padded=[x;zeros(pad_size,1)];
        X_matrix=reshape(x_padded,12,[]);
        X_matrix=X_matrix(:,1:112);
        packet1 = sum( X_matrix(1:6,:) ) > sum( X_matrix(7:12,:) );   
        crcADSB = comm.CRCDetector(logical([1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 0 0 0 0 0 0 1 0 0 1]));
        
        [~,err]=crcADSB(packet1');
       
        if err==0
            k=k+1;
            display("packet found");
           
            recived_packet(k,:)=packet1;
            temp=recived_packet(k,9:32);
          display("ICAO:" )
          binaryVectorToHex(temp,'MSBfirst')
        end
        j=j+1;
             
    end
        
    
end  
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
 