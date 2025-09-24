import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import I18n from "discourse-i18n";

export default class SponsorPostController extends Controller.extend(ModalFunctionality) {
  @tracked selectedDuration = null;
  @tracked selectedProvider = "stripe";
  @tracked isProcessing = false;

  get availableDurations() {
    const durations = this.siteSettings.sponsored_durations_days?.split("|") || ["7", "30"];
    return durations.map(d => ({
      value: parseInt(d),
      label: I18n.t("sponsored.duration_days", { count: parseInt(d) })
    }));
  }

  get availableProviders() {
    const providers = [];
    if (this.siteSettings.sponsored_use_stripe) {
      providers.push({ value: "stripe", label: "Stripe" });
    }
    if (this.siteSettings.sponsored_use_paypal) {
      providers.push({ value: "paypal", label: "PayPal" });
    }
    return providers;
  }

  get canProceed() {
    return this.selectedDuration && this.selectedProvider && !this.isProcessing;
  }

  @action
  selectDuration(duration) {
    this.selectedDuration = duration;
  }

  @action
  selectProvider(provider) {
    this.selectedProvider = provider;
  }

  @action
  async sponsorPost() {
    if (!this.canProceed) return;

    this.isProcessing = true;

    try {
      const result = await ajax("/sponsored/checkout", {
        type: "POST",
        data: {
          post_id: this.model.post.id,
          days: this.selectedDuration,
          provider: this.selectedProvider
        }
      });

      if (result.success) {
        if (result.requires_approval) {
          this.flash(I18n.t("sponsored.submitted_for_approval"), "success");
        } else {
          this.flash(I18n.t("sponsored.activated"), "success");
        }
        this.send("closeModal");
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isProcessing = false;
    }
  }
}