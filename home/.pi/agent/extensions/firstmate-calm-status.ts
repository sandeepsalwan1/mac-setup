import type {
  ExtensionAPI,
  ExtensionUIContext,
} from "@earendil-works/pi-coding-agent";
import { getKeybindings } from "@earendil-works/pi-tui";

const STATUS_KEY = "firstmate-calm-submit";
const ROUND_TRIP_TIMEOUT_MS = 250;

type ToolExpansionRoundTrip = {
  initialExpanded: boolean;
  sawFlip: boolean;
};

export default function (pi: ExtensionAPI) {
  if (process.env.FM_PI_HARNESS !== "pi") return;

  let removeTerminalInputHandler: (() => void) | undefined;
  let restoreToolsExpanded: (() => void) | undefined;
  let activeUi: ExtensionUIContext | undefined;
  let pendingRoundTrip: ToolExpansionRoundTrip | undefined;
  let pendingRoundTripTimeout: ReturnType<typeof setTimeout> | undefined;

  const clearPendingRoundTrip = (): void => {
    if (pendingRoundTripTimeout !== undefined) {
      clearTimeout(pendingRoundTripTimeout);
      pendingRoundTripTimeout = undefined;
    }
    pendingRoundTrip = undefined;
  };

  const clearActiveSession = (): void => {
    removeTerminalInputHandler?.();
    removeTerminalInputHandler = undefined;
    restoreToolsExpanded?.();
    restoreToolsExpanded = undefined;
    activeUi = undefined;
    clearPendingRoundTrip();
  };

  pi.on("session_start", (_event, ctx) => {
    clearActiveSession();
    activeUi = ctx.ui;

    const originalSetToolsExpanded = ctx.ui.setToolsExpanded;
    const quietSetToolsExpanded = (expanded: boolean) => {
      const roundTrip = pendingRoundTrip;
      if (roundTrip === undefined) {
        originalSetToolsExpanded.call(ctx.ui, expanded);
        return;
      }

      if (!roundTrip.sawFlip && expanded !== roundTrip.initialExpanded) {
        roundTrip.sawFlip = true;
        return;
      }
      if (roundTrip.sawFlip && expanded === roundTrip.initialExpanded) {
        clearPendingRoundTrip();
        if (activeUi === ctx.ui) ctx.ui.setStatus(STATUS_KEY, undefined);
        return;
      }

      clearPendingRoundTrip();
      originalSetToolsExpanded.call(ctx.ui, expanded);
    };
    ctx.ui.setToolsExpanded = quietSetToolsExpanded;
    restoreToolsExpanded = () => {
      if (ctx.ui.setToolsExpanded === quietSetToolsExpanded) {
        ctx.ui.setToolsExpanded = originalSetToolsExpanded;
      }
    };

    removeTerminalInputHandler = ctx.ui.onTerminalInput((data) => {
      clearPendingRoundTrip();
      if (!getKeybindings().matches(data, "tui.input.submit")) return;
      if (ctx.ui.getEditorText().trim() !== "/calm") return;

      // Firstmate's handler flips tool expansion twice to repaint existing rows.
      // Pi 0.83+ appends status for each flip, so suppress that exact round trip
      // and request the equivalent quiet repaint when its final call completes.
      const roundTrip = {
        initialExpanded: ctx.ui.getToolsExpanded(),
        sawFlip: false,
      };
      pendingRoundTrip = roundTrip;
      pendingRoundTripTimeout = setTimeout(() => {
        if (pendingRoundTrip !== roundTrip) return;
        pendingRoundTrip = undefined;
        pendingRoundTripTimeout = undefined;
      }, ROUND_TRIP_TIMEOUT_MS);
    });
  });

  pi.on("session_shutdown", (_event, ctx) => {
    if (activeUi === ctx.ui) clearActiveSession();
  });
}
