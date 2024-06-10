
classdef SenStimUI_v2 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        Ax_stimComplete                 matlab.ui.control.UIAxes
        Ax_stimBurst                    matlab.ui.control.UIAxes
        Ax_stimWave                     matlab.ui.control.UIAxes
        StimParametersLabel             matlab.ui.control.Label
        DemoCheckBox                    matlab.ui.control.CheckBox
        StatusPanel                     matlab.ui.container.Panel
        MainStatusLabel                 matlab.ui.control.Label
        SelectedSettingsPanel           matlab.ui.container.Panel
        ElectrodeLabel                  matlab.ui.control.Label
        MonopolarBipolarLabel           matlab.ui.control.Label
        CathodicFirstLabel              matlab.ui.control.Label
        SummarySettings                 matlab.ui.control.Label
        TimeRemainingLabel              matlab.ui.control.Label
        DemoModeLabel                   matlab.ui.control.Label
        MultiStimLabel                  matlab.ui.control.Label
        SettingsPanel                   matlab.ui.container.Panel
        FrequencyHzEditFieldLabel       matlab.ui.control.Label
        FrequencyHzEditField            matlab.ui.control.NumericEditField
        AmplitudemAEditFieldLabel       matlab.ui.control.Label
        AmplitudemAEditField            matlab.ui.control.NumericEditField
        DurationsEditFieldLabel         matlab.ui.control.Label
        DurationsEditField              matlab.ui.control.NumericEditField
        BurstLengthsEditFieldLabel      matlab.ui.control.Label
        BurstLengthsEditField           matlab.ui.control.NumericEditField
        InterburstLengthmsEditFieldLabel  matlab.ui.control.Label
        InterburstLengthmsEditField     matlab.ui.control.NumericEditField
        PreStimWaitmsEditFieldLabel     matlab.ui.control.Label
        PreStimWaitmsEditField          matlab.ui.control.NumericEditField
        PulseWidthsEditFieldLabel       matlab.ui.control.Label
        PulseWidthsEditField            matlab.ui.control.NumericEditField
        InterpulseWidthsEditFieldLabel  matlab.ui.control.Label
        InterpulseWidthsEditField       matlab.ui.control.NumericEditField
        StimElectrodesListBoxLabel      matlab.ui.control.Label
        ListBoxStimElectrodes           matlab.ui.control.ListBox
        BipolarElectrodesListBoxLabel   matlab.ui.control.Label
        ListBoxBipolarElectrodes        matlab.ui.control.ListBox
        ExtrasPanel                     matlab.ui.container.Panel
        BipolarCheckBox                 matlab.ui.control.CheckBox
        CathodicFirstCheckBox           matlab.ui.control.CheckBox
        ControlPanel                    matlab.ui.container.Panel
        ReadyCheckBox                   matlab.ui.control.CheckBox
        GoButton                        matlab.ui.control.Button
        StopButton                      matlab.ui.control.Button
        MultiStimButtonPrevious         matlab.ui.control.Button
        MultiStimButtonNext             matlab.ui.control.Button
        FrontEndDropDownLabel           matlab.ui.control.Label
        FrontEndDropDown                matlab.ui.control.DropDown
        StepSizeADropDownLabel          matlab.ui.control.Label
        StepSizeDropDown                matlab.ui.control.DropDown
        TimeLabel                       matlab.ui.control.Label
        LoadButton                      matlab.ui.control.Button
        SaveButton                      matlab.ui.control.Button
        CurrStatusLabel                 matlab.ui.control.Label
    end


    % ===========================================================================================
    % v2.0
    % Known Issues / Bugs:
    % - Front End selection doesnt check if the appropriate FE is selected. The user needs to 
    % make sure these match.
    % ===========================================================================================
    properties (Access = private)
        ElecsStim
        ElecsBipo
        Frequency 
        Amplitude   
        Duration    
        BurstLen    
        InterBurLen 
        PreStimLen  
        PulseWidth  
        InterPulLen 
        PlotCursor
        NIPisConnected
        CompleteStimDuration
        StimCmdPreStim
        StimCmdBurst
        StimCmdBurstBipo
        StimCmdGap
        StepSizeCurrent
        FrontEndCurrent
        PrevTimeNIP
        MultiStim
        WaitUntilNextStim
        StopButtonWasPushed
        FileName
        LogFolder
    end

    methods (Access = private)
    
        function UpdateStatusPanel(app)
            % === Main status ===
            app.DemoModeLabel.FontColor = 'k';
            if app.DemoCheckBox.Value
                app.DemoModeLabel.Text = 'Demo Mode';
            else
%                 app.DemoModeLabel.Text = 'Connecting to NIP...';
%                 pause(0.01);
                if (TryConnectToNIP(app))
                    app.DemoModeLabel.Text = 'Connected to NIP.';
                    app.DemoModeLabel.FontColor = 'g';
                else
                    app.DemoModeLabel.Text = 'Failed to connect to NIP !';
                    app.DemoModeLabel.FontColor = 'r';
                end
            end
            
            if StimParamsLookOk(app)
                mainStatusString = sprintf('Parameters look good.\n');
                if ~app.ReadyCheckBox.Value
                    mainStatusString = [mainStatusString  'Check ''Ready'' to stim.'];
                end
            else
                mainStatusString = sprintf('Bad parameters.\nPlease verify.');
            end
            app.MainStatusLabel.Text = mainStatusString;
            
            
            % === Selected Settings ===
            if app.BipolarCheckBox.Value && ~isempty(app.ElecsBipo)
                app.ElectrodeLabel.Text = sprintf('Electrodes: %d-%d', app.ElecsStim, app.ElecsBipo);
                app.MonopolarBipolarLabel.Text = 'Stim is Bipolar';
            else
                app.ElectrodeLabel.Text = sprintf('Electrode: %d', app.ElecsStim);
                app.MonopolarBipolarLabel.Text = 'Stim is Monopolar';
            end
            if app.CathodicFirstCheckBox.Value
                app.CathodicFirstLabel.Text = 'Cathodic First';
            else
                app.CathodicFirstLabel.Text = 'Anodic First';
            end
            summaryString = sprintf('Frequency: %d Hz,\n',app.Frequency);
            if mod(abs(app.Amplitude),1) == 0 %check if is integer()
                summaryString = [summaryString sprintf('Amplitude: %d mA,\n',abs(app.Amplitude))];
            else
                summaryString = [summaryString sprintf('Amplitude: %.3f mA,\n',abs(app.Amplitude))];
            end
            if mod(app.Duration,1) == 0 %check if is integer()
                summaryString = [summaryString sprintf('Duration: %d s,\n',app.Duration)];
            else
                summaryString = [summaryString sprintf('Duration: %.3f s,\n',app.Duration)];
            end
            if mod(app.BurstLen,1) == 0 %check if is integer()
                summaryString = [summaryString sprintf('with gaps every %d s,\n',app.BurstLen)];
            else
                summaryString = [summaryString sprintf('with gaps every %.3f s,\n',app.BurstLen)];
            end
            if mod(app.InterBurLen,1) == 0 %check if is integer()
                summaryString = [summaryString sprintf('and gap size of %d ms.',app.InterBurLen)];
            else
                summaryString = [summaryString sprintf('and gap size of %.3f ms.',app.InterBurLen)];
            end
            
            app.SummarySettings.Text = summaryString;
                
            % === Multi Stim  ===
            if ~isempty(app.MultiStim)
                multiStimString = 'Multiple Stims loaded !';
                multiStimString = [multiStimString ...
                    sprintf('\nGap between stims (s): %.2f\n',app.WaitUntilNextStim)];
                multiStimString = [multiStimString ...
                    sprintf('Quantity: %d stims\n',app.MultiStim.NumOfStims)];
                multiStimString = [multiStimString ...
                    sprintf('Total time: %.2f s (%.2f min)\n\n',app.MultiStim.Totaltime,app.MultiStim.Totaltime/60)];
                multiStimString = [multiStimString ...
                    sprintf('Freqs: ')];
                for i = 1:app.MultiStim.NumOfStims
                    multiStimString = [multiStimString sprintf('%3dHz  ',app.MultiStim.St(i).Frequency)];
                    if mod(i-3,4) == 0 || i == 3
                        multiStimString = [multiStimString sprintf('\n')];
                    end
                end
                app.MultiStimLabel.FontColor = [0 128 255]/255;
                app.MultiStimLabel.Text = multiStimString;
            else
                app.MultiStimLabel.Text = '';
            end
        end
        
        function UpdatePlots(app)
            UpdateStimComplete(app);
            UpdateStimBurst(app);
            UpdateStimWave(app);
%             disp('Plots updated')
        end
        
        function UpdateStimComplete(app)
            % Define stimwave
            stimWave_y = [app.Amplitude app.Amplitude ...
                          0 0 ...
                         -app.Amplitude -app.Amplitude];
            stimWave_y = [stimWave_y 0 0];
            
            stimWave_x = [0 app.PulseWidth];
            stimWave_x = [stimWave_x stimWave_x(end)+[0 app.InterPulLen]];
            stimWave_x = [stimWave_x stimWave_x(end)+[0 app.PulseWidth]];
            stimWave_x = stimWave_x*1e-6;
            
            stimPeriod = 1/app.Frequency;
            stimWave_x = [stimWave_x [stimWave_x(end) stimPeriod]];
            
            % Define burst
            % ======================================================
            nStimWaves = floor(app.BurstLen/stimPeriod)+1;
            % ======================================================
            stimBurst_x = repmat(stimWave_x, nStimWaves, 1);
            for i=2:nStimWaves
                stimBurst_x(i,:) = stimBurst_x(i,:) + stimBurst_x(i-1,end);
            end
            stimBurst_x = reshape(stimBurst_x',1,[]);
            stimBurst_y = repmat(stimWave_y, 1, nStimWaves);
            
            % Add Interburst gap
            if app.InterBurLen ~= 0
                stimBurst_y = [stimBurst_y 0];
                stimBurst_x(end) = [];
                stimBurst_x = [stimBurst_x stimBurst_x(end)+[0 app.InterBurLen*1e-3]];
            end
            
            % Define complete stim
            % ======================================================
            nStimBursts = floor(app.Duration/(app.BurstLen + app.InterBurLen*1e-3));
            % ======================================================
            x = repmat(stimBurst_x, nStimBursts, 1);
            for i=2:nStimBursts
                x(i,:) = x(i,:) + x(i-1,end);
            end
            x = reshape(x',1,[]);
            y = repmat(stimBurst_y, 1, nStimBursts);
            
            % Add pre-stim gap
            if app.PreStimLen ~= 0
                y = [0 0 y];
                x = [-app.PreStimLen*1e-3 0 x];
            end
            
            % Plot 
            cla(app.Ax_stimComplete)
            plot(app.Ax_stimComplete,x,y,'LineWidth',.5)
            hold(app.Ax_stimComplete,'on')
            
            if app.PreStimLen ~= 0
                plot(app.Ax_stimComplete,x(1:2),y(1:2),'LineWidth',1,'Color',[0.4660, 0.6740, 0.1880])
            end
            
            app.PlotCursor = plot(app.Ax_stimComplete,[0 0],app.Ax_stimComplete.YLim,'r--',...
                'LineWidth',2.15,'Visible','off');
            app.CompleteStimDuration = x(end) + abs(x(1)); 
            app.CompleteStimDuration = ceil(app.CompleteStimDuration*1e3)*1e-3; % Round to nearest milisecond
            
            if sum(x)==0
                app.Ax_stimComplete.XLim = [-1 1];
            else
                app.Ax_stimComplete.XLim = [x(1) x(end)];
            end
        end
        
        function UpdateStimBurst(app)
            stimWave_y = [app.Amplitude app.Amplitude ...
                          0 0 ...
                         -app.Amplitude -app.Amplitude];
            stimWave_y = [stimWave_y 0 0];
            
            stimWave_x = [0 app.PulseWidth];
            stimWave_x = [stimWave_x stimWave_x(end)+[0 app.InterPulLen]];
            stimWave_x = [stimWave_x stimWave_x(end)+[0 app.PulseWidth]];
            stimWave_x = stimWave_x*1e-6;
            
            stimPeriod = 1/app.Frequency;
            stimWave_x = [stimWave_x [stimWave_x(end) stimPeriod]];
            
            % ======================================================
            nStimWaves = floor(app.BurstLen/stimPeriod)+1;
            % ======================================================
            
            x = repmat(stimWave_x, nStimWaves, 1);
            for i=2:nStimWaves
                x(i,:) = x(i,:) + x(i-1,end);
            end
            x = reshape(x',1,[]);
            y = repmat(stimWave_y, 1, nStimWaves);
            
            % Add pre-stim gap
            if app.PreStimLen ~= 0
                y = [0 0 y];
                x = [-app.PreStimLen*1e-3 0 x];
            end
            
            % Add Interburst gap
            if app.InterBurLen ~= 0
%                 y = [y 0 0];
%                 x = [x x(end)+[0 app.InterBurLen*1e-3]];
                y = [y 0];
                x(end) = [];
                x = [x x(end)+[0 app.InterBurLen*1e-3]];
            end
            
            x = x*1e3;
            
            % Plot 
            cla(app.Ax_stimBurst)
            plot(app.Ax_stimBurst,x,y,'LineWidth',2)
            hold(app.Ax_stimBurst,'on')
            
%             pan(app.Ax_stimBurst,'on');          % or 'off'
%             zoom(app.Ax_stimBurst,'on');         % or 'off'
            
            if app.PreStimLen ~= 0
                plot(app.Ax_stimBurst,x(1:2),y(1:2),'LineWidth',2,'Color',[0.4660, 0.6740, 0.1880])
            end
            
            if app.InterBurLen ~= 0
                plot(app.Ax_stimBurst,x(end-1:end),y(end-1:end),'LineWidth',2,'Color',[0.8500, 0.3250, 0.0980])
            end
            
            if sum(x)==0
                app.Ax_stimBurst.XLim = [-1 1];
            else
                app.Ax_stimBurst.XLim = [x(1) x(end)];
            end
        end
        
        function UpdateStimWave(app)
            y = [0 0 ...
                app.Amplitude app.Amplitude ...
                0 0 ...
                -app.Amplitude -app.Amplitude ...
                0 0];
            x = [-app.PulseWidth 0];
            x = [x x(end)+[0 app.PulseWidth]];
            x = [x x(end)+[0 app.InterPulLen]];
            x = [x x(end)+[0 app.PulseWidth]];
            x = [x x(end)+[0 app.PulseWidth]];
            
            cla(app.Ax_stimWave)
            plot(app.Ax_stimWave,x,y,'LineWidth',2,'DisplayName',sprintf('Elec: %d',app.ElecsStim))
            hold(app.Ax_stimWave,'on')
            
            if ~isempty(app.ElecsBipo)
                plot(app.Ax_stimWave,x,-y,'LineWidth',2,'DisplayName',sprintf('Elec: %d',app.ElecsBipo))
            end
            legend(app.Ax_stimWave);
                
            
            if sum(x)==0
                app.Ax_stimWave.XLim = [-1 1];
            else
                app.Ax_stimWave.XLim = [x(1) x(end)];
            end
        end
        
        function PlayStimPlot(app)
            
            % == Timer settings ==
            % Clear previous timer
            timerPlayPlot = timerfind('Name','timerPlayPlot');
            if ~isempty( timerPlayPlot )
                stop(timerPlayPlot);
                delete(timerPlayPlot);
            end
            tStop = timerfind('Name','tStop');
            if ~isempty( tStop )
                stop(tStop);
                delete(tStop);
            end
            app.PlotCursor.Visible = 'on';
            app.PlotCursor.XData = [app.Ax_stimComplete.XLim(1) app.Ax_stimComplete.XLim(1)]; % Reset to initial pos
%             pause(0.1)
            
            % Prepare next timer
            timerPeriod = app.Duration*.01; % Percentage of duration
%             timerPeriod = 1;
            timerPeriod = max(timerPeriod, 0.05); % Make sure to not go below 10 ms
            timerPlayPlot =  timer('Name','timerPlayPlot');
            startDelay = round(app.CompleteStimDuration*1.1,3);
            % This timer has a 'StartFcn' that waits enough time to run the entire plot then kills the timer with another 'singleShot' timer
            set(timerPlayPlot,...
                'StartFcn', @(~,~)...
                    start(timer('Name','tStop','ExecutionMode','singleShot','StartDelay',startDelay,...% Add an offset afterwards to make sure stim has ended.
                        'TimerFcn',@(~,~)...
                            stop(timerfind('Name','timerPlayPlot'))...
                        )),...
                'ExecutionMode','FixedRate',...
                'Period',timerPeriod,...
                'BusyMode','queue',...
                'StartDelay',timerPeriod,...
                'TimerFcn',@(~,~) ...
                        set(app.PlotCursor,'XData', app.PlotCursor.XData + timerPeriod)...
                    );
                %get(timerfind('Name','timerPlayPlot'),'Period')
                
            % =================== %
            start(timerPlayPlot);
            % =================== %
        end
        
        function result = TryConnectToNIP(app)
            if xippmex('time') == app.PrevTimeNIP
                % Connect
                LockScreenParams(app);
                xippmex('close');
                fprintf('Processor was not connected. Attempting to connect now.. ')
                if xippmex('tcp') ~= 1
                    app.NIPisConnected = false;
                    result = false;
                    fprintf('Failed.\n')
                else
                    app.NIPisConnected = true;
                    result = true;
                    fprintf('Success.\n')
                end
                UnlockScreenParams(app);
            else
                app.NIPisConnected = true;
                result = true;
                app.PrevTimeNIP = xippmex('time');
                pause(0.01);
            end
        end
        
        function result = StimParamsLookOk(app)
            %% TODO CHECK PARAMS
            disp('TODO: check params look good')
            result = true;
        end
        
        function LockScreenParams(app)
            set(findobj(app.UIFigure,'Tag','EditableFields'),'Enable','off')
        end
        
        function UnlockScreenParams(app)
            set(findobj(app.UIFigure,'Tag','EditableFields'),'Enable','on')
            if ~app.BipolarCheckBox.Value
                app.ListBoxBipolarElectrodes.Enable = 'off';
            end
        end
        
        function SetupTags(app)
            app.DemoCheckBox.Tag                = 'EditableFields';
            app.FrequencyHzEditField.Tag        = 'EditableFields';
            app.AmplitudemAEditField.Tag        = 'EditableFields';
            app.DurationsEditField.Tag          = 'EditableFields';
            app.BurstLengthsEditField.Tag       = 'EditableFields';
            app.InterburstLengthmsEditField.Tag = 'EditableFields';
            app.PreStimWaitmsEditField.Tag      = 'EditableFields';
            app.PulseWidthsEditField.Tag        = 'EditableFields';
            app.ReadyCheckBox.Tag               = 'EditableFields';
            app.InterpulseWidthsEditField.Tag   = 'EditableFields';
            app.ListBoxStimElectrodes.Tag       = 'EditableFields';
            app.ListBoxBipolarElectrodes.Tag    = 'EditableFields';
            app.BipolarCheckBox.Tag             = 'EditableFields';
            app.CathodicFirstCheckBox.Tag       = 'EditableFields';
            app.FrontEndDropDown.Tag            = 'EditableFields';
            app.StepSizeDropDown.Tag            = 'EditableFields';
            app.GoButton.Tag                    = 'EditableFields';
        end
        
        function UpdateStimCmd(app)
            app.StimCmdPreStim   = [];
            app.StimCmdBurst     = [];
            app.StimCmdBurstBipo = [];
            app.StimCmdGap       = [];
            
            baseCmd.elec     = app.ElecsStim;
            baseCmd.repeats  = 1;
            baseCmd.period   = [];
            baseCmd.action   = 'allcyc';
            
            app.StimCmdPreStim   = baseCmd;
            app.StimCmdBurst     = baseCmd;
            app.StimCmdBurstBipo = baseCmd;
            app.StimCmdGap       = baseCmd;
            
            % Useful definitions
            fastSettle = 1;
            NIP_timeUnits = 1/30000;
            
            % === StimCmdPreStim ===
            if app.PreStimLen > 0
                preStimLength = round((app.PreStimLen*1e-3)/NIP_timeUnits);
                app.StimCmdPreStim.seq(1) = struct(...
                    'length', preStimLength,...
                    'ampl', 0,...
                    'pol', 1, ...
                    'fs', 0,...
                    'enable', 0,...
                    'delay', 0,...
                    'ampSelect', 1);
                
                app.StimCmdPreStim.period   = sum([app.StimCmdPreStim.seq.length]);
            end
            
            % === StimCmdBurst ===
            len_PW = round((app.PulseWidth*1e-6)/NIP_timeUnits);
            len_IPW = round((app.InterPulLen*1e-6)/NIP_timeUnits);
            stimAmp = abs((app.Amplitude*1e3)/app.StepSizeCurrent);
            
            polarity = ~app.CathodicFirstCheckBox.Value;
            
            app.StimCmdBurst.seq(1) = struct(...
                'length', len_PW,...
                'ampl', stimAmp,...
                'pol', double(polarity), ...
                'fs', fastSettle,...
                'enable', 1,...
                'delay', 0,...
                'ampSelect', 1);
            app.StimCmdBurst.seq(2) = struct(...
                'length', len_IPW,...
                'ampl', 0,...
                'pol', double(polarity), ...
                'fs', fastSettle,...
                'enable', 0,...
                'delay', 0,...
                'ampSelect', 1);
            app.StimCmdBurst.seq(3) = struct(...
                'length', len_PW,...
                'ampl', stimAmp,...
                'pol', double(~polarity), ...
                'fs', fastSettle,...
                'enable', 1,...
                'delay', 0,...
                'ampSelect', 1);
            
            app.StimCmdBurst.period   = 1/(app.Frequency * NIP_timeUnits); 
            app.StimCmdBurst.repeats  = app.Frequency * app.BurstLen;
            
            if app.BipolarCheckBox.Value && ~isempty(app.ElecsBipo)
                app.StimCmdBurstBipo = app.StimCmdBurst;
                app.StimCmdBurstBipo.elec = app.ElecsBipo;
                app.StimCmdBurstBipo.seq(1).pol = double(~polarity);
                app.StimCmdBurstBipo.seq(3).pol = double(polarity);
                app.StimCmdBurstBipo.action = 'curcyc';
                disp(app.StimCmdBurstBipo.action);
            end
            
            % === StimCmdGap ===
            if app.InterBurLen > 0
                interBurLen = round((app.InterBurLen*1e-3)/NIP_timeUnits);
                app.StimCmdGap.seq(1) = struct(...
                    'length', interBurLen,...
                    'ampl', 0,...
                    'pol', 1, ...
                    'fs', 0,...
                    'enable', 0,...
                    'delay', 0,...
                    'ampSelect', 1);
                
                app.StimCmdGap.period   = sum([app.StimCmdGap.seq.length]);
            end
        end
        
        function UpdateStepSize(app)
            if ~app.DemoCheckBox.Value
                LockScreenParams(app);
                xippmex('stim', 'enable', 0); % disable stim
                pause(0.2);
                dropDownItems = cell2mat(cellfun(@str2num,app.StepSizeDropDown.Items,'Uni',0));
                idx = find(app.StepSizeCurrent==dropDownItems);
                try
                    xippmex('stim','res', app.ElecsStim, idx); % update
                catch
                    msg = sprintf('Could not change Step Size (%d µA) on Elecs: (%d).\nPlease restart.',...
                                app.StepSizeCurrent,app.ElecsStim);
                    Abort(app,msg);
                    return
                end
                xippmex('stim', 'enable', 1); % enable stim
                pause(0.2);
                UnlockScreenParams(app);
            end
        end
        
        function SendStim(app)
            % Preparing depending on Demo or not
            app.StimCmdPreStim = []; % get rid of this for now
            if app.DemoCheckBox.Value
                stimFullHandle = @(~,~) disp('DEMO: xippmex(''stimseq'', [app.StimCmdPreStim app.StimCmdBurst app.StimCmdGap])');
                stimBlockHandle = @(~,~) disp('DEMO: xippmex(''stimseq'', [app.StimCmdBurst app.StimCmdGap])');
            else    
                if app.InterburstLengthmsEditField.Value > 0 
                    stimFullHandle = @(~,~) xippmex('stimseq', [app.StimCmdPreStim app.StimCmdBurst app.StimCmdGap]);
                    stimBlockHandle = @(~,~) xippmex('stimseq', [app.StimCmdBurst app.StimCmdGap]);
                else
                    stimFullHandle = @(~,~) xippmex('stimseq', [app.StimCmdPreStim app.StimCmdBurst]);
                    stimBlockHandle = @(~,~) xippmex('stimseq', [app.StimCmdBurst]);
                end
%                 stimFullHandle = @(~,~) xippmex('stimseq', [app.StimCmdPreStim app.StimCmdBurst app.StimCmdBurstBipo app.StimCmdGap]);
%                 stimBlockHandle = @(~,~) xippmex('stimseq', [app.StimCmdBurst app.StimCmdBurstBipo app.StimCmdGap]);
            end
            
            % Checking if we need scheduled stims or if they all fit into one burst
            blockDuration = app.BurstLen + app.InterBurLen*1e-3; % block = (burst+gap)
            timeRemainAfterInit = app.CompleteStimDuration - blockDuration;
            if timeRemainAfterInit < 0 || (timeRemainAfterInit/blockDuration) < 1
                % No need for timers. Everything fits into one burst
                feval(stimFullHandle);
                % If not demo, equals => xippmex('stimseq', [app.StimCmdPreStim app.StimCmdBurst app.StimCmdGap])
                return
            end
            
            % === Preparation ===
            % Clear previous stim timers
            timerStim = timerfind('Name','timerStim');
            if ~isempty( timerStim )
                stop(timerStim);
                delete(timerStim);
            end
            tStopStim = timerfind('Name','tStopStim');
            if ~isempty( tStopStim )
                stop(tStopStim);
                delete(tStopStim);
            end
            % Prepare next timer
            timerPeriod = blockDuration;
            startDelay = round(app.PreStimLen*1e-3 + blockDuration/2,3); % Timer will START at middle of first block (burst+gap)
            endDelay = round(timeRemainAfterInit - blockDuration/3,3); % Timer will END 1/3 of block before "complete stim" end time
            if startDelay > endDelay
                msg = sprintf('Could not schedule timers properly (%.3f) > (%.3f).\nPlease restart.',...
                            startDelay,endDelay);
                Abort(app, msg);
            end
            timerStim =  timer('Name','timerStim');
            % This timer has a 'StartFcn' that waits enough time to run the entire plot then kills the timer with another 'singleShot' timer
            set(timerStim,...
                'StartFcn', @(~,~)...
                    start(timer('Name','tStopStim','ExecutionMode','singleShot','StartDelay',endDelay,...
                        'TimerFcn',@(~,~)...
                            stop(timerfind('Name','timerStim'))...
                        )),...
                'ExecutionMode','FixedRate',...
                'Period',timerPeriod,...
                'BusyMode','queue',...
                'StartDelay',startDelay,...
                'TimerFcn',@(~,~) feval(stimBlockHandle)...
                    );
            
            % === Sending Stims ===
            % Sending first burst
            feval(stimFullHandle);
            % If not demo, equals => xippmex('stimseq', [app.StimCmdPreStim app.StimCmdBurst app.StimCmdGap])
            
            % Starting stim timer
            start(timerStim);
        end
        
        function CheckAmplitudeIsMultipleOfStepSize(app)
            if abs((app.Amplitude*1e3)/app.StepSizeCurrent) < 1
                return
            end
            if mod(app.Amplitude,app.StepSizeCurrent*1e-3) ~= 0
                % Adjust amplitude
                adjstAmp = round(app.Amplitude/(app.StepSizeCurrent*1e-3));
                app.Amplitude = round(adjstAmp*(app.StepSizeCurrent*1e-3),3);
                app.AmplitudemAEditField.Value = app.Amplitude;
                
                EmphasizeField(app,app.AmplitudemAEditField);
            else
                % No need to adjust amplitude
                DeEmphasizeField(app,app.AmplitudemAEditField);
            end
        end
    
        function CheckAmplitudeFitsStepSize(app)
            % The upper limit of stim amplitude varies with step size. If using the maximum 
            % step size, the amplitude can only go to 75 units. Otherwise, can go up to 100.
            dropDownItems = cell2mat(cellfun(@str2num,app.StepSizeDropDown.Items,'Uni',0));
            idx = find(app.StepSizeCurrent==dropDownItems);
            if idx == 5
                upperLimit = 75;
            else
                upperLimit = 100;
            end
            
            stimAmp = abs((app.Amplitude*1e3)/app.StepSizeCurrent);
%             disp(stimAmp)
            if stimAmp >= 1 && stimAmp <= upperLimit
                % No need to adjust anything
                return
            end
            while stimAmp > upperLimit
                idx = idx +1;
                try
                    newStepSize = dropDownItems(idx);
                catch
                    EmphasizeField(app,app.AmplitudemAEditField);
                    Warning(app, sprintf('Amplitude is too high.\nPlease adjust.'));
                    return;
                end
                stimAmp = abs((app.Amplitude*1e3)/newStepSize);
            end
            
            while stimAmp < 1
                idx = idx -1;
                try
                    newStepSize = dropDownItems(idx);
                catch
                    EmphasizeField(app,app.AmplitudemAEditField);
                    Warning(app, sprintf('Amplitude is too low.\nPlease adjust.'));
                    return;
                end
                stimAmp = abs((app.Amplitude*1e3)/newStepSize);
            end
             
            app.StepSizeDropDown.Value = num2str(newStepSize);
            CheckUpdateStepSizeDropDown(app);
        end
        
        function CheckUpdateFrontEndDropDown(app)
            value = app.FrontEndDropDown.Value;
            if strcmp(value, app.FrontEndCurrent)
                return
            end
            app.FrontEndCurrent = value;
            % Hardcoded step size values of each FE. If Ripple changes these we need to update here.
            switch value
                case 'Macro'
                    stepSizeArr = [10 20 50 100 200];  % <= Change here if Ripple changes stepSizes
                case 'Micro'
                    stepSizeArr = [1 2 5 10 20];  % <= Change here if Ripple changes stepSizes
            end
            app.StepSizeDropDown.Items = arrayfun(@num2str,stepSizeArr,'Uni',0);
            app.StepSizeDropDown.Value = app.StepSizeDropDown.Items(end-1);
        end
        
        function CheckUpdateStepSizeDropDown(app)
            value = str2double(app.StepSizeDropDown.Value);
            if value == app.StepSizeCurrent
                return
            end
            
            app.StepSizeCurrent = value;
            
            UpdateStepSize(app);
        end
        
        function Abort(app, msg)
            StopButtonPushed(app, []); % Simulate Stop button to stop any stim
            
            LockScreenParams(app);
            
            app.ReadyCheckBox.Visible = 'off';
            app.GoButton.Visible = 'off';
            
            uiconfirm(app.UIFigure, msg, 'Error !','Options',{'Ok'});
        end
        
        function Warning(app, msg)
            app.ReadyCheckBox.Value = false;
            ReadyCheckBoxValueChanged(app,[]);
            uiconfirm(app.UIFigure, msg, 'Warning !','Options',{'Ok'});
        end
        
        
        function ret = StepSizeIsCorrect(app)
            dropDownItems = cell2mat(cellfun(@str2num,app.StepSizeDropDown.Items,'Uni',0));
            idx = find(app.StepSizeCurrent==dropDownItems);
            stepSize_idx = xippmex('stim','res', app.ElecsStim); 
            if idx == stepSize_idx
                ret = true;
            else
                ret = false;
            end
        end
        
        function SetupClockTime(app)
            try
                timerClock = timerfind('Name','timerClock');
                if ~isempty( timerClock )
                    stop(timerClock);
                    delete(timerClock);
                end
                timerClock = timer('Name','timerClock');
                set(timerClock,...
                    'ExecutionMode','FixedRate',...
                    'Period',0.48,...
                    'BusyMode','queue',...
                    'TimerFcn',@(~,~) ...
                            set(app.TimeLabel,'Text',split(datestr(now),' '))...
                        );
                    
                start(timerClock);
            catch
                app.TimeLabel.Text='';
            end
            
        end
        
        function ApplyLoadedConfig(app, cfg, idx)
            app.FrequencyHzEditField.Value	     = cfg.Frequency;
            app.AmplitudemAEditField.Value	     = cfg.Amplitude;
            app.DurationsEditField.Value	     = cfg.Duration;
            app.BurstLengthsEditField.Value	     = cfg.BurstLen;
            app.InterburstLengthmsEditField.Value    = cfg.IntBurLen;
            app.PreStimWaitmsEditField.Value	     = cfg.PreStiLen;
            app.PulseWidthsEditField.Value	     = cfg.PulseWid;
            app.InterpulseWidthsEditField.Value	     = cfg.IntPulWid;
            app.WaitUntilNextStim		     = cfg.GapBetwSti;
            %
            app.BipolarCheckBox.Value = cfg.BipoChck;
            app.CathodicFirstCheckBox.Value = cfg.CathoChck;
            %
            app.FrontEndDropDown.Value = cfg.FrontEnd;
            app.StepSizeDropDown.Value = num2str(cfg.StepSize);
            
            app.ListBoxStimElectrodes.Value = num2str(cfg.StimElec);
            app.ElecsStim = cfg.StimElec;
            
            SettingsValueChanged(app,[]);
            
            app.ReadyCheckBox.Value = cfg.Ready;
            ReadyCheckBoxValueChanged(app, []);
            
            if ~isempty(idx)
                app.MultiStim.LoadedIdx = idx;
                app.SettingsPanel.Title = sprintf('Settings - Multi Stim (%d out of %d).',idx,app.MultiStim.NumOfStims);

            end
        end
        
        function UnlockScreenParamsWithTimer(app)
            start(timer('Name','reEnableUI','ExecutionMode','singleShot','StartDelay',app.CompleteStimDuration,...
                'TimerFcn',@(~,~)...
                    set(findobj(app.UIFigure,'Tag','EditableFields'),'Enable','on')...
                ))
            
            if ~app.BipolarCheckBox.Value
                start(timer('Name','disableBipoUI','ExecutionMode','singleShot','StartDelay',app.CompleteStimDuration+0.020,...
                    'TimerFcn',@(~,~)...
                        set(app.ListBoxBipolarElectrodes, 'Enable', 'off')...
                    ))
            end
        end
        
        function CheckMultiStimPreviousNextButtons(app)
            if app.MultiStim.LoadedIdx == app.MultiStim.NumOfStims
                app.MultiStimButtonNext.Enable = 'off';
            else
                app.MultiStimButtonNext.Enable = 'on';
            end
            if app.MultiStim.LoadedIdx == 1
                app.MultiStimButtonPrevious.Enable = 'off';
            else
                app.MultiStimButtonPrevious.Enable = 'on';
            end
        end
        
        function WaitForSec(app, t)
            t_ = getQPTime;
            while(getQPTime - t_ < (t-0.5))
                pause(0.5);
                if app.StopButtonWasPushed 
                    return 
                end
            end
            pause(t-(getQPTime-t_));
        end
        
        function SetupStatusLabel(app, t, id)
            switch id
                case 0
                    changeLabelHandle = @(t_) set(app.CurrStatusLabel,'Text',sprintf('OFF\n%d s left',t_));
                case 1
                    changeLabelHandle = @(t_) set(app.CurrStatusLabel,'Text',sprintf('ON\n%d s left',t_));
            end
            feval(changeLabelHandle,t);
            app.CurrStatusLabel.UserData = t;
            try
                timerStatLabel = timerfind('Name','timerStatLabel');
                if ~isempty( timerStatLabel )
                    stop(timerStatLabel);
                    delete(timerStatLabel);
                end
                timerStatLabel = timer('Name','timerStatLabel');
                set(timerStatLabel,...
                    'ExecutionMode','FixedRate',...
                    'Period',1,...
                    'BusyMode','queue',...
                    'TimerFcn',@(~,~) ...
                            feval(changeLabelHandle,app.CurrStatusLabel.UserData)...
                        );
                timerUpdateCurrTimeLeft = timerfind('Name','timerUpdateCurrTimeLeft');
                if ~isempty( timerUpdateCurrTimeLeft )
                    stop(timerUpdateCurrTimeLeft);
                    delete(timerUpdateCurrTimeLeft);
                end
                timerUpdateCurrTimeLeft= timer('Name','timerUpdateCurrTimeLeft');
                set(timerUpdateCurrTimeLeft,...
                    'ExecutionMode','FixedRate',...
                    'Period',1,...
                    'StartDelay',1,...
                    'BusyMode','queue',...
                    'TimerFcn',@(~,~) ...
                            set(app.CurrStatusLabel,'UserData',app.CurrStatusLabel.UserData-1)...
                        );
                    
                start(timerUpdateCurrTimeLeft);
                start(timerStatLabel);
            catch
                app.CurrStatusLabel.Text='';
            end
            
        end
        
        function EmphasizeField(app,field)
            field.FontWeight = 'bold';
            field.BackgroundColor = [255 120 0]/255;
        end
        function DeEmphasizeField(app,field)
            field.FontWeight = 'normal';
            field.BackgroundColor = [1 1 1];
        end
        
        function LogStim(app)
            dnow = datestr(now,'HH-MM-SS');
            if isempty(app.FileName)
                fname = fullfile(app.LogFolder,['StLog_' dnow '_0.txt']);
            else
                fname = fullfile(app.LogFolder,['StLog_' app.FileName '_' dnow '_0.txt']);
            end
            id = 1;
            while isfile(fname)
                fname(end-5:end) = [];
                fname = [fname '_' num2str(id) '.txt'];
                id = id +1;
            end
            
            if app.CathodicFirstCheckBox.Value
                strCathAnode = 'Cathodic First';
            else
                strCathAnode = 'Anodic First';
            end
            
            str = [sprintf('Freq: %d Hz\nAmpl: %.3f mA\nElectr: %d\nDuration: %.3f s\n',app.Frequency,abs(app.Amplitude),app.ElecsStim,app.Duration) ...
                  sprintf('Burst Length: %.3f s\nInterBurst Length (gaps): %.3f ms\n',app.BurstLen, app.InterBurLen)...
                  sprintf('PreStim Wait: %.3f ms\nPulseWidth: %.3f µs\n',app.PreStimLen,app.PulseWidth)...
                  sprintf('InterPulseWidth: %.3f µs\nStepSize: %d µA\n%s\n',app.InterPulLen,app.StepSizeCurrent,strCathAnode)...
                  app.FrontEndCurrent];
            
            fileID = fopen(fname,'w');
            fprintf(fileID,str);
            fclose(fileID);
        end
        
    end


    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.UIFigure.Name = 'Stim UI v2 for Ripple - By Luciano Branco';
            % Initialize some variables
            app.StepSizeCurrent = 0;
            app.FrontEndCurrent = 0;
            app.PrevTimeNIP = 0; % Dont change this (impacts TryConnectToNIP)
            app.MultiStim = [];
            app.WaitUntilNextStim = [];
            app.StopButtonWasPushed = false;
            app.MultiStimButtonPrevious.Visible = 'off';
            app.MultiStimButtonNext.Visible = 'off';
            app.CurrStatusLabel.Visible = 'off';
            app.FileName = [];
            app.LogFolder = 'StimLogs';
            
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            folder = mkdir(app.LogFolder);
            warning('on', 'MATLAB:MKDIR:DirectoryExists');
            
            SetupClockTime(app);
            
    app.ListBoxStimElectrodes.Items = arrayfun(@num2str,1:32,'Uni',0); %temp 
    app.ListBoxBipolarElectrodes.Items = arrayfun(@num2str,1:32,'Uni',0);%temp 
                
            if ~app.DemoCheckBox.Value
                if ~TryConnectToNIP(app)
                    msg = {'Could not connect to the NIP.','What do you wish to do?'};
                    title = 'Attention !';
                    selection = uiconfirm(app.UIFigure,msg,title, ...
                               'Options',{'Try again','Enable Demo mode'}, ...
                               'DefaultOption',1);
                    switch selection
                       case 'Try again'
                           TryConnectToNIP(app);
                       case 'Enable Demo mode'
                           app.DemoCheckBox.Value = true;
                    end
                end
            end
            
            if app.DemoCheckBox.Value 
                disp('Demo ON')
                app.ListBoxStimElectrodes.Items = arrayfun(@num2str,1:32,'Uni',0);
                app.ListBoxBipolarElectrodes.Items = arrayfun(@num2str,1:32,'Uni',0);
            else
                %TODO read available electrodes
                disp('Demo OFF')
            end
            app.ListBoxStimElectrodes.UserData    = 'ListBoxStimElectrodes';
            app.ListBoxBipolarElectrodes.UserData = 'ListBoxBipolarElectrodes';
            app.StepSizeDropDown.UserData         = 'DropDownStepSize';
            
            app.ListBoxStimElectrodes.Value = app.ListBoxStimElectrodes.Items{1};
            app.ElecsStim = str2double(app.ListBoxStimElectrodes.Value);
            app.ElecsBipo = [];
            
            SetupTags(app);
            
            SettingsValueChanged(app,[]);
        end

        % Value changed function: BipolarCheckBox
        function BipolarCheckBoxValueChanged(app, event)
            value = app.BipolarCheckBox.Value;
            if value
                app.ListBoxBipolarElectrodes.Enable = 'on';
            else
                app.ListBoxBipolarElectrodes.Enable = 'off';
                app.ListBoxBipolarElectrodes.Value = {};
                app.ElecsBipo = [];
            end
            
            SettingsValueChanged(app,[]);
        end

        % Button pushed function: GoButton
        function GoButtonPushed(app, event)
            if isempty(app.MultiStim)
                LockScreenParams(app);
                
                if ~app.DemoCheckBox.Value
                    if ~StepSizeIsCorrect(app)
                        UpdateStepSize(app);
                        if ~StepSizeIsCorrect(app)
                            Abort(app, "Step size is incorrect.\nPlease restart.")
                            return
                        end
                    end
                    xippmex('stim','enable',1)
                end
                SendStim(app);
                LogStim(app);
                
                PlayStimPlot(app);
                
                UnlockScreenParamsWithTimer(app);
            else
                % Multistim
                app.StopButtonWasPushed = false;
                
                app.MultiStimButtonNext.Enable = 'off';
                app.MultiStimButtonPrevious.Enable = 'off';
                
                flagFirstIter = true;
                for i = app.MultiStim.LoadedIdx : app.MultiStim.NumOfStims
                    ApplyLoadedConfig(app,app.MultiStim.St(i), i);
                    app.GoButton.Enable = 'off';
                    
                    % Wait for gaps between stims
                    if ~flagFirstIter
                        SetupStatusLabel(app,app.WaitUntilNextStim, 0)
                        WaitForSec(app, app.WaitUntilNextStim)
                    end
                    if ~app.DemoCheckBox.Value
                        if ~StepSizeIsCorrect(app)
                            UpdateStepSize(app);
                            if ~StepSizeIsCorrect(app)
                                Abort(app, "Step size is incorrect.\nPlease restart.")
                                return
                            end
                        end
                        xippmex('stim','enable',1)
                    end
                    if app.StopButtonWasPushed
                        break
                    end
                    
                    SetupStatusLabel(app,app.MultiStim.St(i).Duration, 1)
                    
                    SendStim(app);
                    LogStim(app);
                    PlayStimPlot(app);
                    
                    % Wait for stim to execute
                    WaitForSec(app, app.MultiStim.St(i).Duration)
                    
                    if app.StopButtonWasPushed
                        break
                    end
                    flagFirstIter = false;
                end
                timerStatLabel = timerfind('Name','timerStatLabel');
                if ~isempty( timerStatLabel )
                    stop(timerStatLabel);
                    delete(timerStatLabel);
                end
                timerUpdateCurrTimeLeft = timerfind('Name','timerUpdateCurrTimeLeft');
                if ~isempty( timerUpdateCurrTimeLeft )
                    stop(timerUpdateCurrTimeLeft);
                    delete(timerUpdateCurrTimeLeft);
                end
                app.CurrStatusLabel.Text = 'All done.';
                
                app.GoButton.Enable = 'on';
                CheckMultiStimPreviousNextButtons(app);
            end
        end

        % Value changed function: ReadyCheckBox
        function ReadyCheckBoxValueChanged(app, event)
            value = app.ReadyCheckBox.Value;
            if value
                app.GoButton.Enable = 'on';
            else
                app.GoButton.Enable = 'off';
            end
        end

        % Value changed function: AmplitudemAEditField, 
        % BurstLengthsEditField, CathodicFirstCheckBox, 
        % DurationsEditField, FrequencyHzEditField, FrontEndDropDown, 
        % InterburstLengthmsEditField, InterpulseWidthsEditField, 
        % ListBoxBipolarElectrodes, ListBoxStimElectrodes, 
        % PreStimWaitmsEditField, PulseWidthsEditField, StepSizeDropDown
        function SettingsValueChanged(app, event)
            app.ReadyCheckBox.Value = false;
            ReadyCheckBoxValueChanged(app, event);
            
            try
                if strcmp(event.Source.Type,'uilistbox')
                    switch event.Source.UserData
                        case 'ListBoxStimElectrodes'
%                             disp('Main')
                            app.ElecsStim = str2double(event.Value);
                        case 'ListBoxBipolarElectrodes'
%                             disp('Bipo')
                            app.ElecsBipo = str2double(event.Value);
                    end
                end
            end
            app.Frequency     = app.FrequencyHzEditField.Value;    
            app.Duration      = app.DurationsEditField.Value;
            app.BurstLen      = app.BurstLengthsEditField.Value;
            app.InterBurLen   = app.InterburstLengthmsEditField.Value;
            app.PreStimLen    = app.PreStimWaitmsEditField.Value;
            app.PulseWidth    = app.PulseWidthsEditField.Value;
            app.InterPulLen   = app.InterpulseWidthsEditField.Value;
            if app.CathodicFirstCheckBox.Value
                app.Amplitude     = -app.AmplitudemAEditField.Value;
            else
                app.Amplitude     = app.AmplitudemAEditField.Value;
            end
            CheckUpdateFrontEndDropDown(app);
            CheckUpdateStepSizeDropDown(app);
            
            CheckAmplitudeIsMultipleOfStepSize(app);
            CheckAmplitudeFitsStepSize(app);
            
            UpdateStatusPanel(app);
            UpdatePlots(app);
            
            UpdateStimCmd(app);
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.StopButtonWasPushed = true;
            
            if ~app.DemoCheckBox.Value
                xippmex('stim','enable',0); % Kill any stim
            end
            
            % Clear previous stim timers
            timerStim = timerfind('Name','timerStim');
            if ~isempty( timerStim )
                stop(timerStim);
                delete(timerStim);
            end
            tStopStim = timerfind('Name','tStopStim');
            if ~isempty( tStopStim )
                stop(tStopStim);
                delete(tStopStim);
            end
            
            timerPlayPlot = timerfind('Name','timerPlayPlot');
            if ~isempty( timerPlayPlot )
                stop(timerPlayPlot);
                delete(timerPlayPlot);
            end
            
            ReEnableUI = timerfind('Name','reEnableUI');
            if ~isempty( ReEnableUI )
                stop(ReEnableUI);
                delete(ReEnableUI);
            end
            disableBipoUI = timerfind('Name','disableBipoUI');
            if ~isempty( disableBipoUI )
                stop(disableBipoUI);
                delete(disableBipoUI);
            end
            timerStatLabel = timerfind('Name','timerStatLabel');
            if ~isempty( timerStatLabel )
                stop(timerStatLabel);
                delete(timerStatLabel);
            end
            timerUpdateCurrTimeLeft = timerfind('Name','timerUpdateCurrTimeLeft');
            if ~isempty( timerUpdateCurrTimeLeft )
                stop(timerUpdateCurrTimeLeft);
                delete(timerUpdateCurrTimeLeft);
            end
            if isempty(app.MultiStim)
                % Renable UI manually
                UnlockScreenParams(app);
                
                app.ReadyCheckBox.Value = false;
                ReadyCheckBoxValueChanged(app, event);
                
            end
        end

        % Value changed function: DemoCheckBox
        function DemoCheckBoxValueChanged(app, event)
            value = app.DemoCheckBox.Value;
            if value
                app.DemoCheckBox.FontWeight = 'bold';
                app.DemoCheckBox.FontColor = [230 0 0]/255;
                app.DemoCheckBox.FontSize = 18;
            else
                app.DemoCheckBox.FontWeight = 'normal';
                app.DemoCheckBox.FontColor = [0 0 0];
                app.DemoCheckBox.FontSize = 16;
            end
            SettingsValueChanged(app, event);
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app)
            
            timerClock = timerfind('Name','timerClock');
            if ~isempty( timerClock )
                stop(timerClock);
                delete(timerClock);
            end
            
            % Clear previous stim timers
            timerStim = timerfind('Name','timerStim');
            if ~isempty( timerStim )
                stop(timerStim);
                delete(timerStim);
            end
            tStopStim = timerfind('Name','tStopStim');
            if ~isempty( tStopStim )
                stop(tStopStim);
                delete(tStopStim);
            end
            
            timerPlayPlot = timerfind('Name','timerPlayPlot');
            if ~isempty( timerPlayPlot )
                stop(timerPlayPlot);
                delete(timerPlayPlot);
            end
            
            ReEnableUI = timerfind('Name','reEnableUI');
            if ~isempty( ReEnableUI )
                stop(ReEnableUI);
                delete(ReEnableUI);
            end
            disableBipoUI = timerfind('Name','disableBipoUI');
            if ~isempty( disableBipoUI )
                stop(disableBipoUI);
                delete(disableBipoUI);
            end
            timerStatLabel = timerfind('Name','timerStatLabel');
            if ~isempty( timerStatLabel )
                stop(timerStatLabel);
                delete(timerStatLabel);
            end
            timerUpdateCurrTimeLeft = timerfind('Name','timerUpdateCurrTimeLeft');
            if ~isempty( timerUpdateCurrTimeLeft )
                stop(timerUpdateCurrTimeLeft);
                delete(timerUpdateCurrTimeLeft);
            end
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            [filename, pathname] = uigetfile( ...
                {'*.csv;', 'CSV file (*.csv)'}, 'Pick a File to Import');
            full_filename = fullfile(pathname, filename);
            app.FileName = filename;
            
            T = readtable(full_filename,'HeaderLines',1);
            T_mat = T{:,:};
            if size(T_mat,1) == 1 % Only one entry => no Multistim
                if ~T_mat(1)
                    FE_choice = 'Macro';
                else
                    FE_choice = 'Micro';
                end
                st = struct(...
                    'FrontEnd',FE_choice,...
                    'StepSize'	,T_mat(1,2),...
		    'Frequency'	,T_mat(1,3),...
                    'Amplitude' ,T_mat(1,4),...
                    'Duration'	,T_mat(1,5),...
                    'BurstLen'	,T_mat(1,6),...
                    'IntBurLen'	,T_mat(1,7),...
                    'PreStiLen'	,T_mat(1,8),...
                    'PulseWid'	,T_mat(1,9),...
                    'IntPulWid'	,T_mat(1,10),...
                    'StimElec'	,T_mat(1,11),...
                    'BipoElec'	,T_mat(1,12),...
                    'BipoChck'	,T_mat(1,13),...
                    'CathoChck'	,T_mat(1,14),...
                    'Ready'	,T_mat(1,15),...
                    'GapBetwSti',T_mat(1,16)...
                    );
                app.MultiStim = [];
                
                ApplyLoadedConfig(app,st, [])
                
                app.SettingsPanel.Title = 'Settings - (Loaded)';
                UnlockScreenParams(app);
                
                app.GoButton.Text = 'Go';
                app.GoButton.BackgroundColor = [0.298 0.7333 0.0902];
                
                app.MultiStimButtonPrevious.Visible = 'off';
                app.MultiStimButtonNext.Visible = 'off';
                app.CurrStatusLabel.Visible = 'off';
                return
            end
            
            % Decode input, hardcoded for now
            numStims = size(T_mat,1);
            for i = 1:numStims 
                if ~T_mat(i,1)
                    FE_choice = 'Macro';
                else
                    FE_choice = 'Micro';
                end
                st(i) = struct(...
                    'FrontEnd',FE_choice,...
                    'StepSize'	,T_mat(i,2),...
		    'Frequency'	,T_mat(i,3),...
                    'Amplitude' ,T_mat(i,4),...
                    'Duration'	,T_mat(i,5),...
                    'BurstLen'	,T_mat(i,6),...
                    'IntBurLen'	,T_mat(i,7),...
                    'PreStiLen'	,T_mat(i,8),...
                    'PulseWid'	,T_mat(i,9),...
                    'IntPulWid'	,T_mat(i,10),...
                    'StimElec'	,T_mat(i,11),...
                    'BipoElec'	,T_mat(i,12),...
                    'BipoChck'	,T_mat(i,13),...
                    'CathoChck'	,T_mat(i,14),...
                    'Ready'	,T_mat(i,15),...
                    'GapBetwSti',T_mat(i,16)...
                    );
            end
            app.MultiStim.NumOfStims = numStims;
            app.MultiStim.St = st;
            app.MultiStim.Totaltime = sum(T_mat(:,5));
            app.WaitUntilNextStim = st(1).GapBetwSti;
            
            SettingsValueChanged(app,[]);
            
            LockScreenParams(app);
            
            app.ReadyCheckBox.Value = true;
            app.GoButton.Text = 'Go Multi Stim';
            app.GoButton.BackgroundColor = [0 128 255]/255;
%             
            ReadyCheckBoxValueChanged(app, event);
            
            app.MultiStimButtonPrevious.Visible = 'on';
            app.MultiStimButtonPrevious.Enable = 'off';
            app.MultiStimButtonNext.Visible = 'on';
            app.CurrStatusLabel.Text = 'Waiting';
            app.CurrStatusLabel.Visible = 'on';
            
            
            ApplyLoadedConfig(app,app.MultiStim.St(1), 1);
            app.GoButton.Enable = 'on';
            CheckMultiStimPreviousNextButtons(app)
        end

        % Button pushed function: MultiStimButtonPrevious
        function MultiStimButtonPreviousPushed(app, event)

            app.MultiStim.LoadedIdx = app.MultiStim.LoadedIdx - 1;
            
            CheckMultiStimPreviousNextButtons(app);
            
            ApplyLoadedConfig(app,app.MultiStim.St(app.MultiStim.LoadedIdx), app.MultiStim.LoadedIdx);
            
            app.GoButton.Enable = 'on';
        end

        % Button pushed function: MultiStimButtonNext
        function MultiStimButtonNextPushed(app, event)
            
            app.MultiStim.LoadedIdx = app.MultiStim.LoadedIdx + 1;
            
            CheckMultiStimPreviousNextButtons(app);
            
            ApplyLoadedConfig(app,app.MultiStim.St(app.MultiStim.LoadedIdx), app.MultiStim.LoadedIdx);
            
            app.GoButton.Enable = 'on';
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 781 978];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create Ax_stimComplete
            app.Ax_stimComplete = uiaxes(app.UIFigure);
            title(app.Ax_stimComplete, 'Complete Stim')
            xlabel(app.Ax_stimComplete, 'Time (s)')
            ylabel(app.Ax_stimComplete, 'Amplitude (mA)')
            app.Ax_stimComplete.Box = 'on';
            app.Ax_stimComplete.XGrid = 'on';
            app.Ax_stimComplete.YGrid = 'on';
            app.Ax_stimComplete.Position = [251 734 522 185];

            % Create Ax_stimBurst
            app.Ax_stimBurst = uiaxes(app.UIFigure);
            title(app.Ax_stimBurst, 'Stim burst')
            xlabel(app.Ax_stimBurst, 'Time (ms)')
            ylabel(app.Ax_stimBurst, 'Amplitude (mA)')
            app.Ax_stimBurst.Box = 'on';
            app.Ax_stimBurst.XGrid = 'on';
            app.Ax_stimBurst.YGrid = 'on';
            app.Ax_stimBurst.Position = [251 550 522 185];

            % Create Ax_stimWave
            app.Ax_stimWave = uiaxes(app.UIFigure);
            title(app.Ax_stimWave, 'Stim waveform')
            xlabel(app.Ax_stimWave, 'Time (µs)')
            ylabel(app.Ax_stimWave, 'Amplitude (mA)')
            app.Ax_stimWave.Box = 'on';
            app.Ax_stimWave.XGrid = 'on';
            app.Ax_stimWave.YGrid = 'on';
            app.Ax_stimWave.Position = [251 366 522 185];

            % Create StimParametersLabel
            app.StimParametersLabel = uilabel(app.UIFigure);
            app.StimParametersLabel.HorizontalAlignment = 'center';
            app.StimParametersLabel.FontSize = 28;
            app.StimParametersLabel.FontWeight = 'bold';
            app.StimParametersLabel.Position = [280 939 228 40];
            app.StimParametersLabel.Text = 'Stim Parameters';

            % Create DemoCheckBox
            app.DemoCheckBox = uicheckbox(app.UIFigure);
            app.DemoCheckBox.ValueChangedFcn = createCallbackFcn(app, @DemoCheckBoxValueChanged, true);
            app.DemoCheckBox.Text = 'Demo';
            app.DemoCheckBox.FontSize = 16;
            app.DemoCheckBox.Position = [11 877 81 22];

            % Create StatusPanel
            app.StatusPanel = uipanel(app.UIFigure);
            app.StatusPanel.Title = 'Status';
            app.StatusPanel.BackgroundColor = [1 1 1];
            app.StatusPanel.FontAngle = 'italic';
            app.StatusPanel.FontSize = 16;
            app.StatusPanel.Position = [11 360 230 509];

            % Create MainStatusLabel
            app.MainStatusLabel = uilabel(app.StatusPanel);
            app.MainStatusLabel.FontSize = 14;
            app.MainStatusLabel.Position = [11 404 210 40];
            app.MainStatusLabel.Text = {'Parameters look good.'; 'Check ready to stim'};

            % Create SelectedSettingsPanel
            app.SelectedSettingsPanel = uipanel(app.StatusPanel);
            app.SelectedSettingsPanel.BorderType = 'none';
            app.SelectedSettingsPanel.TitlePosition = 'centertop';
            app.SelectedSettingsPanel.Title = 'Selected Settings';
            app.SelectedSettingsPanel.BackgroundColor = [1 1 1];
            app.SelectedSettingsPanel.FontAngle = 'italic';
            app.SelectedSettingsPanel.FontSize = 16;
            app.SelectedSettingsPanel.Position = [1 4 220 200];

            % Create ElectrodeLabel
            app.ElectrodeLabel = uilabel(app.SelectedSettingsPanel);
            app.ElectrodeLabel.FontSize = 14;
            app.ElectrodeLabel.Position = [11 147 200 20];
            app.ElectrodeLabel.Text = 'Electrode: ';

            % Create MonopolarBipolarLabel
            app.MonopolarBipolarLabel = uilabel(app.SelectedSettingsPanel);
            app.MonopolarBipolarLabel.FontSize = 14;
            app.MonopolarBipolarLabel.Position = [11 127 200 20];
            app.MonopolarBipolarLabel.Text = 'MonopolarBipolar';

            % Create CathodicFirstLabel
            app.CathodicFirstLabel = uilabel(app.SelectedSettingsPanel);
            app.CathodicFirstLabel.FontSize = 14;
            app.CathodicFirstLabel.Position = [11 107 200 20];
            app.CathodicFirstLabel.Text = 'CathodicFirst';

            % Create SummarySettings
            app.SummarySettings = uilabel(app.SelectedSettingsPanel);
            app.SummarySettings.FontSize = 14;
            app.SummarySettings.Position = [11 18 200 79];
            app.SummarySettings.Text = {'Frequency: 100 Hz, '; 'Amplitude: 1 mA, '; 'Duration: 15 s, '; 'with gaps every 1 s'; 'and gap size 50 ms'};

            % Create TimeRemainingLabel
            app.TimeRemainingLabel = uilabel(app.StatusPanel);
            app.TimeRemainingLabel.FontSize = 14;
            app.TimeRemainingLabel.Position = [11 374 180 20];
            app.TimeRemainingLabel.Text = 'Time Remaining (s): 15';

            % Create DemoModeLabel
            app.DemoModeLabel = uilabel(app.StatusPanel);
            app.DemoModeLabel.FontSize = 14;
            app.DemoModeLabel.Position = [10 458 210 22];
            app.DemoModeLabel.Text = 'Demo Mode';

            % Create MultiStimLabel
            app.MultiStimLabel = uilabel(app.StatusPanel);
            app.MultiStimLabel.VerticalAlignment = 'top';
            app.MultiStimLabel.FontSize = 14;
            app.MultiStimLabel.FontColor = [0 0.451 0.7412];
            app.MultiStimLabel.Position = [11 214 200 150];
            app.MultiStimLabel.Text = '';

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.UIFigure);
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.FontAngle = 'italic';
            app.SettingsPanel.FontSize = 16;
            app.SettingsPanel.Position = [11 9 760 350];

            % Create FrequencyHzEditFieldLabel
            app.FrequencyHzEditFieldLabel = uilabel(app.SettingsPanel);
            app.FrequencyHzEditFieldLabel.HorizontalAlignment = 'right';
            app.FrequencyHzEditFieldLabel.FontSize = 16;
            app.FrequencyHzEditFieldLabel.Position = [51 221 116 22];
            app.FrequencyHzEditFieldLabel.Text = 'Frequency (Hz)';

            % Create FrequencyHzEditField
            app.FrequencyHzEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.FrequencyHzEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.FrequencyHzEditField.Position = [182 221 100 22];
            app.FrequencyHzEditField.Value = 100;

            % Create AmplitudemAEditFieldLabel
            app.AmplitudemAEditFieldLabel = uilabel(app.SettingsPanel);
            app.AmplitudemAEditFieldLabel.HorizontalAlignment = 'right';
            app.AmplitudemAEditFieldLabel.FontSize = 16;
            app.AmplitudemAEditFieldLabel.Position = [51 191 116 22];
            app.AmplitudemAEditFieldLabel.Text = 'Amplitude (mA)';

            % Create AmplitudemAEditField
            app.AmplitudemAEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.AmplitudemAEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.AmplitudemAEditField.Position = [182 191 100 22];
            app.AmplitudemAEditField.Value = 1;

            % Create DurationsEditFieldLabel
            app.DurationsEditFieldLabel = uilabel(app.SettingsPanel);
            app.DurationsEditFieldLabel.HorizontalAlignment = 'right';
            app.DurationsEditFieldLabel.FontSize = 16;
            app.DurationsEditFieldLabel.Position = [78 161 89 22];
            app.DurationsEditFieldLabel.Text = 'Duration (s)';

            % Create DurationsEditField
            app.DurationsEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.DurationsEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.DurationsEditField.Position = [182 161 100 22];
            app.DurationsEditField.Value = 15;

            % Create BurstLengthsEditFieldLabel
            app.BurstLengthsEditFieldLabel = uilabel(app.SettingsPanel);
            app.BurstLengthsEditFieldLabel.HorizontalAlignment = 'right';
            app.BurstLengthsEditFieldLabel.FontSize = 16;
            app.BurstLengthsEditFieldLabel.Position = [48 131 119 22];
            app.BurstLengthsEditFieldLabel.Text = 'Burst Length (s)';

            % Create BurstLengthsEditField
            app.BurstLengthsEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.BurstLengthsEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.BurstLengthsEditField.Position = [182 131 100 22];
            app.BurstLengthsEditField.Value = 1;

            % Create InterburstLengthmsEditFieldLabel
            app.InterburstLengthmsEditFieldLabel = uilabel(app.SettingsPanel);
            app.InterburstLengthmsEditFieldLabel.HorizontalAlignment = 'right';
            app.InterburstLengthmsEditFieldLabel.FontSize = 16;
            app.InterburstLengthmsEditFieldLabel.Position = [4 101 163 22];
            app.InterburstLengthmsEditFieldLabel.Text = 'Interburst Length (ms)';

            % Create InterburstLengthmsEditField
            app.InterburstLengthmsEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.InterburstLengthmsEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.InterburstLengthmsEditField.Position = [182 101 100 22];
            app.InterburstLengthmsEditField.Value = 50;

            % Create PreStimWaitmsEditFieldLabel
            app.PreStimWaitmsEditFieldLabel = uilabel(app.SettingsPanel);
            app.PreStimWaitmsEditFieldLabel.HorizontalAlignment = 'right';
            app.PreStimWaitmsEditFieldLabel.FontSize = 16;
            app.PreStimWaitmsEditFieldLabel.Position = [27 71 140 22];
            app.PreStimWaitmsEditFieldLabel.Text = 'Pre-Stim Wait (ms)';

            % Create PreStimWaitmsEditField
            app.PreStimWaitmsEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.PreStimWaitmsEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.PreStimWaitmsEditField.Position = [182 71 100 22];
            app.PreStimWaitmsEditField.Value = 20;

            % Create PulseWidthsEditFieldLabel
            app.PulseWidthsEditFieldLabel = uilabel(app.SettingsPanel);
            app.PulseWidthsEditFieldLabel.HorizontalAlignment = 'right';
            app.PulseWidthsEditFieldLabel.FontSize = 16;
            app.PulseWidthsEditFieldLabel.Position = [44 41 123 22];
            app.PulseWidthsEditFieldLabel.Text = 'Pulse Width (µs)';

            % Create PulseWidthsEditField
            app.PulseWidthsEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.PulseWidthsEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.PulseWidthsEditField.Position = [182 41 100 22];
            app.PulseWidthsEditField.Value = 100;

            % Create InterpulseWidthsEditFieldLabel
            app.InterpulseWidthsEditFieldLabel = uilabel(app.SettingsPanel);
            app.InterpulseWidthsEditFieldLabel.HorizontalAlignment = 'right';
            app.InterpulseWidthsEditFieldLabel.FontSize = 16;
            app.InterpulseWidthsEditFieldLabel.Position = [14 11 153 22];
            app.InterpulseWidthsEditFieldLabel.Text = 'Interpulse Width (µs)';

            % Create InterpulseWidthsEditField
            app.InterpulseWidthsEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.InterpulseWidthsEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.InterpulseWidthsEditField.Position = [182 11 100 22];
            app.InterpulseWidthsEditField.Value = 100;

            % Create StimElectrodesListBoxLabel
            app.StimElectrodesListBoxLabel = uilabel(app.SettingsPanel);
            app.StimElectrodesListBoxLabel.HorizontalAlignment = 'center';
            app.StimElectrodesListBoxLabel.VerticalAlignment = 'bottom';
            app.StimElectrodesListBoxLabel.Position = [300 298 100 22];
            app.StimElectrodesListBoxLabel.Text = 'Stim Electrodes';

            % Create ListBoxStimElectrodes
            app.ListBoxStimElectrodes = uilistbox(app.SettingsPanel);
            app.ListBoxStimElectrodes.Items = {};
            app.ListBoxStimElectrodes.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.ListBoxStimElectrodes.Position = [291 11 119 281];
            app.ListBoxStimElectrodes.Value = {};

            % Create BipolarElectrodesListBoxLabel
            app.BipolarElectrodesListBoxLabel = uilabel(app.SettingsPanel);
            app.BipolarElectrodesListBoxLabel.HorizontalAlignment = 'center';
            app.BipolarElectrodesListBoxLabel.VerticalAlignment = 'bottom';
            app.BipolarElectrodesListBoxLabel.Position = [428 299 103 22];
            app.BipolarElectrodesListBoxLabel.Text = 'Bipolar Electrodes';

            % Create ListBoxBipolarElectrodes
            app.ListBoxBipolarElectrodes = uilistbox(app.SettingsPanel);
            app.ListBoxBipolarElectrodes.Items = {};
            app.ListBoxBipolarElectrodes.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.ListBoxBipolarElectrodes.Enable = 'off';
            app.ListBoxBipolarElectrodes.Position = [420 11 119 282];
            app.ListBoxBipolarElectrodes.Value = {};

            % Create ExtrasPanel
            app.ExtrasPanel = uipanel(app.SettingsPanel);
            app.ExtrasPanel.BorderType = 'none';
            app.ExtrasPanel.TitlePosition = 'centertop';
            app.ExtrasPanel.Title = 'Extras';
            app.ExtrasPanel.FontAngle = 'italic';
            app.ExtrasPanel.FontSize = 14;
            app.ExtrasPanel.Position = [551 232 200 80];

            % Create BipolarCheckBox
            app.BipolarCheckBox = uicheckbox(app.ExtrasPanel);
            app.BipolarCheckBox.ValueChangedFcn = createCallbackFcn(app, @BipolarCheckBoxValueChanged, true);
            app.BipolarCheckBox.Text = 'Bipolar';
            app.BipolarCheckBox.FontSize = 16;
            app.BipolarCheckBox.Position = [11 32 80 22];

            % Create CathodicFirstCheckBox
            app.CathodicFirstCheckBox = uicheckbox(app.ExtrasPanel);
            app.CathodicFirstCheckBox.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.CathodicFirstCheckBox.Text = 'Cathodic First';
            app.CathodicFirstCheckBox.FontSize = 16;
            app.CathodicFirstCheckBox.Position = [11 6 121 22];

            % Create ControlPanel
            app.ControlPanel = uipanel(app.SettingsPanel);
            app.ControlPanel.BorderType = 'none';
            app.ControlPanel.TitlePosition = 'centertop';
            app.ControlPanel.Title = 'Control';
            app.ControlPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ControlPanel.FontAngle = 'italic';
            app.ControlPanel.FontSize = 14;
            app.ControlPanel.Position = [551 5 200 230];

            % Create ReadyCheckBox
            app.ReadyCheckBox = uicheckbox(app.ControlPanel);
            app.ReadyCheckBox.ValueChangedFcn = createCallbackFcn(app, @ReadyCheckBoxValueChanged, true);
            app.ReadyCheckBox.Text = 'Ready';
            app.ReadyCheckBox.FontSize = 16;
            app.ReadyCheckBox.Position = [11 178 70 22];

            % Create GoButton
            app.GoButton = uibutton(app.ControlPanel, 'push');
            app.GoButton.ButtonPushedFcn = createCallbackFcn(app, @GoButtonPushed, true);
            app.GoButton.BackgroundColor = [0.298 0.7333 0.0902];
            app.GoButton.FontSize = 20;
            app.GoButton.FontWeight = 'bold';
            app.GoButton.FontColor = [1 1 1];
            app.GoButton.Enable = 'off';
            app.GoButton.Position = [11 110 180 40];
            app.GoButton.Text = 'Go';

            % Create StopButton
            app.StopButton = uibutton(app.ControlPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.BackgroundColor = [0.902 0 0];
            app.StopButton.FontSize = 20;
            app.StopButton.FontWeight = 'bold';
            app.StopButton.FontColor = [1 1 1];
            app.StopButton.Position = [11 10 180 90];
            app.StopButton.Text = 'Stop';

            % Create MultiStimButtonPrevious
            app.MultiStimButtonPrevious = uibutton(app.ControlPanel, 'push');
            app.MultiStimButtonPrevious.ButtonPushedFcn = createCallbackFcn(app, @MultiStimButtonPreviousPushed, true);
            app.MultiStimButtonPrevious.BackgroundColor = [0 0 0];
            app.MultiStimButtonPrevious.FontSize = 18;
            app.MultiStimButtonPrevious.FontWeight = 'bold';
            app.MultiStimButtonPrevious.FontColor = [1 1 1];
            app.MultiStimButtonPrevious.Position = [107 160 37 40];
            app.MultiStimButtonPrevious.Text = '<<';

            % Create MultiStimButtonNext
            app.MultiStimButtonNext = uibutton(app.ControlPanel, 'push');
            app.MultiStimButtonNext.ButtonPushedFcn = createCallbackFcn(app, @MultiStimButtonNextPushed, true);
            app.MultiStimButtonNext.BackgroundColor = [0 0 0];
            app.MultiStimButtonNext.FontSize = 18;
            app.MultiStimButtonNext.FontWeight = 'bold';
            app.MultiStimButtonNext.FontColor = [1 1 1];
            app.MultiStimButtonNext.Position = [153 160 37 40];
            app.MultiStimButtonNext.Text = '>>';

            % Create FrontEndDropDownLabel
            app.FrontEndDropDownLabel = uilabel(app.SettingsPanel);
            app.FrontEndDropDownLabel.HorizontalAlignment = 'right';
            app.FrontEndDropDownLabel.FontSize = 16;
            app.FrontEndDropDownLabel.Position = [89 281 76 22];
            app.FrontEndDropDownLabel.Text = 'Front End';

            % Create FrontEndDropDown
            app.FrontEndDropDown = uidropdown(app.SettingsPanel);
            app.FrontEndDropDown.Items = {'Macro', 'Micro'};
            app.FrontEndDropDown.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.FrontEndDropDown.FontSize = 14;
            app.FrontEndDropDown.Position = [180 281 100 22];
            app.FrontEndDropDown.Value = 'Macro';

            % Create StepSizeADropDownLabel
            app.StepSizeADropDownLabel = uilabel(app.SettingsPanel);
            app.StepSizeADropDownLabel.HorizontalAlignment = 'right';
            app.StepSizeADropDownLabel.FontSize = 16;
            app.StepSizeADropDownLabel.Position = [56 253 109 22];
            app.StepSizeADropDownLabel.Text = 'Step Size (µA)';

            % Create StepSizeDropDown
            app.StepSizeDropDown = uidropdown(app.SettingsPanel);
            app.StepSizeDropDown.Items = {'10', '20', '50', '100', '200'};
            app.StepSizeDropDown.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.StepSizeDropDown.FontSize = 14;
            app.StepSizeDropDown.Position = [180 253 100 22];
            app.StepSizeDropDown.Value = '100';

            % Create TimeLabel
            app.TimeLabel = uilabel(app.UIFigure);
            app.TimeLabel.HorizontalAlignment = 'right';
            app.TimeLabel.FontSize = 18;
            app.TimeLabel.Position = [531 919 230 50];
            app.TimeLabel.Text = 'Time';

            % Create LoadButton
            app.LoadButton = uibutton(app.UIFigure, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.FontSize = 16;
            app.LoadButton.Position = [11 942 80 27];
            app.LoadButton.Text = 'Load';

            % Create SaveButton
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.FontSize = 16;
            app.SaveButton.Enable = 'off';
            app.SaveButton.Position = [101 942 80 27];
            app.SaveButton.Text = 'Save';

            % Create CurrStatusLabel
            app.CurrStatusLabel = uilabel(app.UIFigure);
            app.CurrStatusLabel.HorizontalAlignment = 'center';
            app.CurrStatusLabel.FontSize = 24;
            app.CurrStatusLabel.FontWeight = 'bold';
            app.CurrStatusLabel.Position = [101 869 140 60];
            app.CurrStatusLabel.Text = 'All Done';
        end
    end

    methods (Access = public)

        % Construct app
        function app = SenStimUI_v2

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
