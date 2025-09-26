function findme()
% Interactive KLT tracker with robust camera/file fallback.
% q to quit. Requires Computer Vision Toolbox.
% Optional: Image Acquisition Toolbox (for videoinput) or USB Webcam Support Package.

clearvars -except -regexp ^(ans)$
close all; clc

%% ---------- GUI ----------
Fig  = figure('Position',[500,450,980,500],'Name','Interactive KLT Tracker',...
              'Color','w','KeyPressFcn',@onKey);
Pnl1 = uipanel(Fig,'Position',[0.05,0.17,0.9,0.8]);
Pnl2 = uipanel(Fig,'Position',[0.05,0.05,0.9,0.1]);

Axes1 = axes(Pnl1,'Position',[0.00,0,0.5,1]); % live view
Axes2 = axes(Pnl1,'Position',[0.50,0,0.5,1]); % ROI preview

Bt = uicontrol(Pnl2,'style','togglebutton','String','Lock Target','Fontsize',16,...
    'Units','normalized','Position',[0.4,0,0.2,1],'Callback',@LockTarget);

drawnow;

%% ---------- Capture init with fallback ----------
[CAP, mode, errmsg] = initCapture();
if strcmp(mode,'none')
    errordlg(sprintf('No video source available.\n%s',errmsg),'Capture Error');
    return;
end

% First frame
frame = grabFrame(CAP, mode);
if isempty(frame)
    errordlg('Failed to grab initial frame.','Capture Error');
    cleanup();
    return;
end
imshow(frame,'Parent',Axes1); title(Axes1,sprintf('Source: %s',mode));

%% ---------- Tracker state ----------
flag = false;                          % tracking on/off
tracker = vision.PointTracker('MaxBidirectionalError',1);
gap = 1;                               % downsample factor
objFrame = [];
points = [];
lastTic = tic; fps = 0;

%% ---------- Main loop ----------
while isvalid(Fig)
    frame = grabFrame(CAP, mode);
    if isempty(frame); break; end
    frameD = im2double(frame);

    if flag
        % Track
        [pt,valid] = tracker(frameD(1:gap:end,1:gap:end,:));
        pt = pt(valid,:);

        % Reinitialize if tracking lost
        if size(pt,1) < 20 && ~isempty(points)
            release(tracker);
            initialize(tracker, points.Location, objFrame);
            [pt,valid] = tracker(frameD(1:gap:end,1:gap:end,:));
            pt = pt(valid,:);
        end

        ptDisp = pt * gap; % Display points in original image scale
        vis = insertMarker(frame, ptDisp, '+','Color','green');

        % FPS calculation
        dt = toc(lastTic); lastTic = tic;
        if dt > 0, fps = 0.9*fps + 0.1*(1/dt); end
        vis = insertText(vis,[8 8],sprintf('FPS: %.1f | valid: %d',fps,size(ptDisp,1)),...
                         'FontSize',14,'BoxOpacity',0.4,'TextColor','yellow');

        imshow(vis,'Parent',Axes1);
    else
        imshow(frame,'Parent',Axes1);
    end
    drawnow;
end

cleanup();

%% ---------- Callbacks ----------
    function LockTarget(~,~)
        % Use current frame for ROI selection and tracker initialization
        frame = grabFrame(CAP, mode); % Always get latest frame
        frameD = im2double(frame);
        objFrame = frameD(1:gap:end,1:gap:end,:);
        imshow(frame,'Parent',Axes2);
        title(Axes2,'Drag two clicks to define ROI');
        [x,y,~] = ginput(2);
        rect = [min(x),min(y),abs(diff(x)),abs(diff(y))];
        roi = rect./gap;

        GRAY = rgb2gray(objFrame);
        points = detectMinEigenFeatures(GRAY,'ROI',roi);
        pre = insertMarker(objFrame, points.Location,'+','Color','green');
        imshow(pre,'Parent',Axes2); title(Axes2,'ROI features');

        release(tracker);
        initialize(tracker, points.Location, objFrame);
        flag = true;
    end

    function onKey(~,e)
        if strcmpi(e.Key,'q')
            cleanup(); % Ensure cleanup
            delete(Fig);
        end
    end

    function cleanup()
        try
            release(tracker);
            switch mode
                case 'webcam', clear CAP;
                case 'imaq'
                    stop(CAP.vid); delete(CAP.vid); clear CAP;
            end
        catch, end
    end

%% ---------- Helpers ----------
    function [CAP, mode, msg] = initCapture()
        CAP = struct(); mode = 'none'; msg = '';
        % 1) webcam() ���ȣ���ƽ̨��
        try
            cam = webcam; % need USB Webcam Support Package
            CAP.cam = cam; mode = 'webcam'; return;
        catch ME
            msg = [msg, sprintf('[webcam] %s\n', ME.message)];
        end
        % 2) videoinput('winvideo',...) ��ѡ��Windows + IAT ��������
        try
            info = imaqhwinfo;
            if isfield(info,'InstalledAdaptors') && any(strcmpi(info.InstalledAdaptors,'winvideo'))
                vid = videoinput('winvideo',1); %#ok<VINSETUP>
                src = getselectedsource(vid); %#ok<NASGU>
                triggerconfig(vid,'manual');
                start(vid);
                CAP.vid = vid; mode = 'imaq'; return;
            else
                msg = [msg, sprintf('[videoinput] winvideo adaptor not installed.\n')];
            end
        catch ME
            msg = [msg, sprintf('[videoinput] %s\n', ME.message)];
        end
        % 3) ������Ƶ����
        cand = {'samples/sample.mp4','sample.mp4','samples/sample.avi'};
        for k=1:numel(cand)
            if exist(cand{k},'file')
                vr = VideoReader(cand{k});
                CAP.vr = vr; mode = 'file'; return;
            end
        end
        msg = [msg, sprintf('No fallback video found in ./samples/.')];
    end

    function frame = grabFrame(CAP, mode)
        switch mode
            case 'webcam'
                frame = snapshot(CAP.cam);
            case 'imaq'
                frame = getsnapshot(CAP.vid);
            case 'file'
                if hasFrame(CAP.vr)
                    frame = readFrame(CAP.vr);
                else
                    CAP.vr.CurrentTime = 0; % loop
                    frame = readFrame(CAP.vr);
                end
            otherwise
                frame = [];
        end
    end
end
