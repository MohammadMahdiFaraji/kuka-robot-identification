function plot_joints(t, y, yhat, symbol, unit, file)
% PLOT_JOINTS  Six joint plots under each other, like the figures of the paper, saved as PNG.
% Blue: measured signal. Red: model output (leave yhat empty for no model).
fig = figure('Visible', 'off', 'Position', [0 0 1000 900]);
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
        % the legend goes above the first plot; keep the plot as large as the other five
        position = get(gca, 'Position');
        legend({'measured', 'model'}, 'Location', 'northoutside', 'Orientation', 'horizontal');
        set(gca, 'Position', position);
    end
end
xlabel('Time (s)');
exportgraphics(fig, file, 'Resolution', 120);
close(fig);
end
