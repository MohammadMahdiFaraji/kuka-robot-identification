function plot_joints(t, y, yhat, symbol, unit, file)
% PLOT_JOINTS  Six joint plots under each other, like the figures of the paper, saved as PNG.
% Blue: measured signal. Red: model output (leave yhat empty for no model).
fig = figure('Visible', 'off');
for j = 1:6
    subplot(6, 1, j);
    plot(t, y(j,:), 'b');
    hold on;
    if ~isempty(yhat)
        plot(t, yhat(j,:), 'r');
    end
    ylabel(sprintf('%s%d (%s)', symbol, j, unit));
    grid on;
    xlim([t(1) t(end)]);
    if j == 1 && ~isempty(yhat)
        % legend at a fixed place at the top of the figure, above the first plot,
        % so that the first plot keeps the same size as the other five
        lgd = legend({'measured', 'model'}, 'Orientation', 'horizontal');
        lgd.Position = [0.4 0.94 0.2 0.025];
    end
end
xlabel('Time (s)');
% the size of the picture is set as a paper size (10 x 9 inches) and not with the window:
% MATLAB makes a window smaller when it is taller than the screen, and then some figures
% came out smaller than others
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 10 9];
print(fig, file, '-dpng', '-r120');
close(fig);
end
